-- Database schema for Toko Jago Sumberarum
-- Gunakan ini sebagai dasar SQLite atau sesuaikan untuk MySQL/PostgreSQL.

PRAGMA foreign_keys = ON;

-- Tabel pengguna / akun
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'staff',
  email TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Kategori barang
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT
);

-- Supplier / pemasok barang
CREATE TABLE IF NOT EXISTS suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  notes TEXT
);

-- Daftar produk / barang
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category_id INTEGER,
  supplier_id INTEGER,
  purchase_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'pcs',
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- Transaksi barang masuk
CREATE TABLE IF NOT EXISTS stock_in (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  supplier_id INTEGER,
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  purchase_price REAL NOT NULL DEFAULT 0,
  total_amount REAL NOT NULL GENERATED ALWAYS AS (quantity * purchase_price) VIRTUAL,
  transaction_date TEXT NOT NULL DEFAULT (date('now')),
  note TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Transaksi barang keluar
CREATE TABLE IF NOT EXISTS stock_out (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  transaction_date TEXT NOT NULL DEFAULT (date('now')),
  destination TEXT,
  note TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Lihat stok terakhir masing-masing produk
CREATE VIEW IF NOT EXISTS product_stock AS
SELECT
  p.id AS product_id,
  p.sku,
  p.name AS product_name,
  p.unit,
  COALESCE(SUM(si.quantity), 0) AS total_in,
  COALESCE(SUM(so.quantity), 0) AS total_out,
  COALESCE(SUM(si.quantity), 0) - COALESCE(SUM(so.quantity), 0) AS current_stock
FROM products p
LEFT JOIN stock_in si ON si.product_id = p.id
LEFT JOIN stock_out so ON so.product_id = p.id
GROUP BY p.id;

-- Contoh data awal
INSERT OR IGNORE INTO users (username, password, full_name, role, email)
VALUES ('admin', 'admin123', 'Admin Toko', 'admin', 'admin@toko.local');

INSERT OR IGNORE INTO categories (name, description)
VALUES
  ('Makanan', 'Produk makanan dan minuman'),
  ('Peralatan', 'Peralatan rumah tangga dan kios');

INSERT OR IGNORE INTO suppliers (name, phone, email, address)
VALUES
  ('CV. Sumberarum', '081234567890', 'info@sumberarum.co.id', 'Jalan Raya Sumberarum 12'),
  ('PT. Jago Niaga', '082345678901', 'sales@jagoniaga.id', 'Kawasan Industri Sumberarum');

INSERT OR IGNORE INTO products (sku, name, category_id, supplier_id, purchase_price, sale_price, unit)
VALUES
  ('BRG001', 'Indomie Goreng', 1, 1, 2500, 3800, 'bungkus'),
  ('BRG002', 'Susu Kental Manis', 1, 2, 8000, 12000, 'kaleng');

INSERT OR IGNORE INTO stock_in (product_id, supplier_id, quantity, purchase_price, transaction_date)
VALUES
  (1, 1, 50, 2500, '2026-05-01'),
  (2, 2, 30, 8000, '2026-05-01');

INSERT OR IGNORE INTO stock_out (product_id, quantity, destination, transaction_date)
VALUES
  (1, 5, 'Penjualan', '2026-05-02');
