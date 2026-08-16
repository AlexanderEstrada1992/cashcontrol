require('dotenv').config();

const express = require('express');
const oracledb = require('oracledb');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/api/health', async (req, res) => {
  let connection;

  try {
    connection = await oracledb.getConnection({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECT_STRING
    });

    const result = await connection.execute(
      `SELECT 'CONNECTED' AS STATUS FROM DUAL`
    );

    res.status(200).json({
      success: true,
      message: 'API de CashControl funcionando correctamente',
      database: result.rows[0][0]
    });
  } catch (error) {
    console.error('Error de conexión con Oracle:', error.message);

    res.status(500).json({
      success: false,
      message: 'La API está funcionando, pero no fue posible conectar con Oracle'
    });
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (error) {
        console.error('Error al cerrar la conexión:', error.message);
      }
    }
  }
});

app.listen(PORT, () => {
  console.log(`Servidor CashControl ejecutándose en http://localhost:${PORT}`);
});