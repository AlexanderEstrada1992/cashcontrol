const oracledb = require('oracledb');

class AuthStore {
  constructor() {
    this.ready = null;
  }

  connection() {
    return oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECT_STRING });
  }

  async initialize() {
    this.ready ??= this.createSchema().catch(error => { this.ready = null; throw error; });
    await this.ready;
  }

  async createSchema() {
    const connection = await this.connection();
    try {
      for (const statement of [
        `CREATE TABLE CC_USERS (
          USER_ID VARCHAR2(100) PRIMARY KEY,
          USERNAME VARCHAR2(100) NOT NULL UNIQUE,
          EMAIL VARCHAR2(254) UNIQUE,
          PASSWORD_HASH VARCHAR2(255) NOT NULL,
          ROLE VARCHAR2(20) DEFAULT 'user' NOT NULL CHECK (ROLE IN ('user', 'admin')),
          ACTIVE NUMBER(1) DEFAULT 1 NOT NULL CHECK (ACTIVE IN (0, 1)),
          CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
        )`,
        `CREATE TABLE CC_REFRESH_SESSIONS (
          TOKEN_HASH VARCHAR2(64) PRIMARY KEY,
          USER_ID VARCHAR2(100) NOT NULL REFERENCES CC_USERS(USER_ID) ON DELETE CASCADE,
          EXPIRES_AT TIMESTAMP NOT NULL
        )`
      ]) {
        try { await connection.execute(statement); }
        catch (error) { if (error.errorNum !== 955) throw error; }
      }
      for (const [name, hash, role] of [
        [process.env.AUTH_USER, process.env.AUTH_PASSWORD_HASH, 'user'],
        [process.env.AUTH_ADMIN_USER, process.env.AUTH_ADMIN_PASSWORD_HASH, 'admin']
      ]) {
        if (!name || !hash) continue;
        await connection.execute(
          `MERGE INTO CC_USERS target USING (SELECT :username AS username FROM DUAL) source
            ON (target.USERNAME = source.username)
            WHEN NOT MATCHED THEN INSERT (USER_ID, USERNAME, PASSWORD_HASH, ROLE)
            VALUES (:userId, :username, :passwordHash, :role)`,
          { username: name.toLowerCase(), userId: name, passwordHash: hash, role }
        );
      }
      await connection.commit();
    } finally { await connection.close(); }
  }

  async withConnection(action) {
    await this.initialize();
    const connection = await this.connection();
    try { return await action(connection); }
    finally { await connection.close(); }
  }

  mapUser(row) {
    return row ? { id: row.USER_ID, username: row.USERNAME, email: row.EMAIL,
      passwordHash: row.PASSWORD_HASH, role: row.ROLE, active: row.ACTIVE === 1 } : null;
  }

  findUser(username) {
    return this.withConnection(async connection => {
      const result = await connection.execute('SELECT * FROM CC_USERS WHERE USERNAME = :username',
        { username }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      return this.mapUser(result.rows[0]);
    });
  }

  findUserById(id) {
    return this.withConnection(async connection => {
      const result = await connection.execute('SELECT * FROM CC_USERS WHERE USER_ID = :userId',
        { userId: id }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      return this.mapUser(result.rows[0]);
    });
  }

  createUser(user) {
    return this.withConnection(connection => connection.execute(
      `INSERT INTO CC_USERS (USER_ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE)
        VALUES (:userId, :username, :email, :passwordHash, 'user')`,
      { userId: user.id, username: user.username, email: user.email, passwordHash: user.passwordHash },
      { autoCommit: true }
    ));
  }

  saveSession(session) {
    return this.withConnection(async connection => {
      await connection.execute('DELETE FROM CC_REFRESH_SESSIONS WHERE EXPIRES_AT <= SYSTIMESTAMP');
      await connection.execute(
        'INSERT INTO CC_REFRESH_SESSIONS (TOKEN_HASH, USER_ID, EXPIRES_AT) VALUES (:hash, :userId, :expiresAt)', session
      );
      await connection.commit();
    });
  }

  rotateSession(oldHash, session) {
    return this.withConnection(async connection => {
      const result = await connection.execute(
        `DELETE FROM CC_REFRESH_SESSIONS WHERE TOKEN_HASH = :hash AND USER_ID = :userId
          AND EXPIRES_AT > SYSTIMESTAMP`, { hash: oldHash, userId: session.userId }
      );
      if (!result.rowsAffected) return false;
      await connection.execute(
        'INSERT INTO CC_REFRESH_SESSIONS (TOKEN_HASH, USER_ID, EXPIRES_AT) VALUES (:hash, :userId, :expiresAt)', session
      );
      await connection.commit();
      return true;
    });
  }

  listUsers() {
    return this.withConnection(async connection => {
      const result = await connection.execute(
        'SELECT USER_ID, USERNAME, ROLE FROM CC_USERS ORDER BY USERNAME FETCH FIRST 100 ROWS ONLY',
        {}, { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      return result.rows.map(row => ({ id: row.USER_ID, username: row.USERNAME, role: row.ROLE }));
    });
  }
}

module.exports = { AuthStore };