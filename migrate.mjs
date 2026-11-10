import { createHash } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createConnection } from 'mysql2/promise'

const HERE = dirname(fileURLToPath(import.meta.url))
const MIGRATION_ID = '0000_initial_users'
const HISTORY_TABLE = 'ultima_ronda_schema_migrations'
const USERS_TABLE = 'users'
const REQUIRED_USERS_COLUMNS = {
  id: { type: 'int', nullable: 'NO', extra: 'auto_increment' },
  openid: { type: 'varchar(64)', nullable: 'NO' },
  name: { type: 'text', nullable: 'YES' },
  email: { type: 'varchar(320)', nullable: 'YES' },
  loginmethod: { type: 'varchar(64)', nullable: 'YES' },
  role: { type: "enum('user','admin')", nullable: 'NO' },
  createdat: { type: 'timestamp', nullable: 'NO' },
  updatedat: { type: 'timestamp', nullable: 'NO' },
  lastsignedin: { type: 'timestamp', nullable: 'NO' },
}

function fail(message) {
  console.error(message)
  process.exitCode = 1
}

async function tableExists(connection, tableName) {
  const [rows] = await connection.execute(
    'SELECT COUNT(*) AS total FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
    [tableName],
  )
  return Number(rows[0]?.total ?? 0) > 0
}

async function inspectUsers(connection) {
  if (!await tableExists(connection, USERS_TABLE)) return { exists: false, compatible: false, reason: 'missing' }
  const [columns] = await connection.query('SHOW COLUMNS FROM `users`')
  const byName = new Map(columns.map((column) => [String(column.Field).toLowerCase(), column]))
  const missing = []
  const mismatched = []

  for (const [name, expected] of Object.entries(REQUIRED_USERS_COLUMNS)) {
    const column = byName.get(name)
    if (!column) {
      missing.push(name)
      continue
    }
    const type = String(column.Type).toLowerCase().replaceAll(' ', '')
    const nullable = String(column.Null).toUpperCase()
    const extra = String(column.Extra).toLowerCase()
    if (type !== expected.type || nullable !== expected.nullable || (expected.extra && !extra.includes(expected.extra))) {
      mismatched.push(name)
    }
  }

  const [indexes] = await connection.query('SHOW INDEX FROM `users`')
  const primaryId = indexes.some((index) => index.Key_name === 'PRIMARY' && String(index.Column_name).toLowerCase() === 'id')
  const uniqueOpenId = indexes.some((index) => Number(index.Non_unique) === 0 && String(index.Column_name).toLowerCase() === 'openid')
  if (!primaryId) mismatched.push('primary-key(id)')
  if (!uniqueOpenId) mismatched.push('unique(openId)')

  const compatible = missing.length === 0 && mismatched.length === 0
  const details = [
    missing.length ? `missing ${missing.join(', ')}` : '',
    mismatched.length ? `incompatible ${mismatched.join(', ')}` : '',
  ].filter(Boolean).join('; ')
  return { exists: true, compatible, reason: details || 'matches OAuth schema' }
}

async function inspectHistory(connection) {
  if (!await tableExists(connection, HISTORY_TABLE)) return { exists: false, compatible: false }
  const [columns] = await connection.query('SHOW COLUMNS FROM `ultima_ronda_schema_migrations`')
  const byName = new Map(columns.map((column) => [String(column.Field).toLowerCase(), column]))
  const id = byName.get('migration_id')
  const checksum = byName.get('checksum')
  const appliedAt = byName.get('applied_at')
  const compatible = Boolean(id && checksum && appliedAt)
    && String(id.Type).toLowerCase() === 'varchar(80)'
    && String(checksum.Type).toLowerCase() === 'char(64)'
    && String(id.Null).toUpperCase() === 'NO'
    && String(checksum.Null).toUpperCase() === 'NO'
  return { exists: true, compatible }
}

async function run() {
  const args = process.argv.slice(2)
  if (args.some((arg) => arg !== '--apply' && arg !== '--status')) {
    fail('Uso: npm run migrate -- [--status | --apply]')
    return
  }
  const apply = args.includes('--apply')
  const databaseUrl = process.env.DATABASE_URL
  if (!databaseUrl) {
    fail('Falta DATABASE_URL; no se ejecutó ninguna migración.')
    return
  }

  const sql = await readFile(join(HERE, '0000_initial_users.sql'), 'utf8')
  const checksum = createHash('sha256').update(sql).digest('hex')
  let connection
  try {
    connection = await createConnection(databaseUrl)
    const users = await inspectUsers(connection)
    const history = await inspectHistory(connection)

    if (users.exists && !users.compatible) {
      fail(`Migración detenida: la tabla users existente no coincide (${users.reason}); no se modificó.`)
      return
    }
    if (history.exists && !history.compatible) {
      fail(`Migración detenida: ${HISTORY_TABLE} tiene un esquema incompatible; no se modificó.`)
      return
    }

    let record = null
    if (history.exists) {
      const [rows] = await connection.execute(
        'SELECT checksum FROM `ultima_ronda_schema_migrations` WHERE migration_id = ?',
        [MIGRATION_ID],
      )
      record = rows[0] ?? null
    }

    if (record && record.checksum !== checksum) {
      fail(`Migración detenida: el checksum registrado para ${MIGRATION_ID} no coincide con el archivo; no se modificó.`)
      return
    }
    if (record && !users.exists) {
      fail(`Migración detenida: ${MIGRATION_ID} aparece registrada pero falta users; no se modificó.`)
      return
    }
    if (record) {
      console.log(`${MIGRATION_ID}: aplicada; esquema users verificado.`)
      return
    }
    if (!apply) {
      console.log(users.exists
        ? `${MIGRATION_ID}: users ya coincide; falta registrar esta migración. Ejecuta --apply para completar el historial.`
        : `${MIGRATION_ID}: pendiente; no se escribió en la base. Ejecuta --apply para crear users.`)
      return
    }

    if (!history.exists) {
      await connection.query(`CREATE TABLE \`${HISTORY_TABLE}\` (
        \`migration_id\` varchar(80) NOT NULL,
        \`checksum\` char(64) NOT NULL,
        \`applied_at\` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (\`migration_id\`)
      )`)
    }
    if (!users.exists) await connection.query(sql)

    const verifiedUsers = await inspectUsers(connection)
    if (!verifiedUsers.exists || !verifiedUsers.compatible) {
      fail(`Migración detenida tras aplicar SQL: la comprobación de users falló (${verifiedUsers.reason}). No se registró como completa.`)
      return
    }
    await connection.execute(
      'INSERT INTO `ultima_ronda_schema_migrations` (`migration_id`, `checksum`) VALUES (?, ?)',
      [MIGRATION_ID, checksum],
    )
    console.log(`${MIGRATION_ID}: aplicada y verificada; solo se creó o registró el esquema de usuarios.`)
  } catch (error) {
    const code = typeof error?.code === 'string' ? ` (${error.code})` : ''
    fail(`Error de migración de base de datos${code}; no se muestran credenciales ni detalles de conexión.`)
  } finally {
    if (connection) {
      try {
        await connection.end()
      } catch {
        // The migration result is already determined; release errors carry no schema action.
      }
    }
  }
}

await run()
