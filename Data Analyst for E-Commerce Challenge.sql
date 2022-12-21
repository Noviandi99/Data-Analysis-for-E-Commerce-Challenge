-- cek table yang digunakan
SELECT * FROM orders;
SELECT * FROM order_details;
SELECT * FROM products;
SELECT * FROM users;

-- Jumlah Transaksi per Bulan
SELECT
  DATE_FORMAT(created_at, '%Y-%m') AS Bulan,
  COUNT(1) AS jumlah_transaksi
FROM orders
GROUP BY 1
ORDER BY 1;

-- Status Transaksi
	-- Jumlah transaksi yang tidak dibayar
SELECT
  COUNT(1) AS transaksi_tidak_dibayar
FROM orders
WHERE paid_at = 'NA';

	-- Jumlah transaksi yang sudah dibayar tapi tidak dikirim
SELECT
  COUNT(1) AS transaksi_dibayar_tidak_dikirim
FROM orders
WHERE paid_at != 'NA'
AND delivery_at = 'NA';

	-- Jumlah transaksi yang tidak dikirim, baik yang sudah dibayar maupun belum
SELECT
  COUNT(1) AS transaksi_tidak_dikirim
FROM orders
WHERE delivery_at = 'NA'
AND (paid_at != 'NA'
OR paid_at = 'NA');

	-- Jumlah transaksi yang dikirim pada hari yang sama dengan tanggal dibayar
SELECT
  COUNT(1) AS jumlah_transaksi
FROM orders
WHERE paid_at = delivery_at;

-- Pengguna Bertransaksi
	-- Total seluruh pengguna
SELECT
  COUNT(DISTINCT user_id) AS jumlah_seluruh_pengguna
FROM users;

    -- Total pengguna yang pernah bertransaksi sebagai pembeli
SELECT
  COUNT(DISTINCT buyer_id) AS jumlah_buyer
FROM orders;

    -- Total pengguna yang pernah bertransaksi sebagai penjual
SELECT
  COUNT(DISTINCT seller_id) AS jumlah_seller
FROM orders;

    -- Total pengguna yang pernah bertransaksi sebagai pembeli dan pernah sebagai penjual
SELECT
  COUNT(DISTINCT seller_id) AS buyer_and_seller
FROM orders
WHERE seller_id IN (SELECT
  buyer_id
FROM orders);

    -- Total pengguna yang tidak pernah bertransaksi sebagai pembeli maupun penjual
SELECT
  COUNT(DISTINCT user_id) AS pengguna_tidak_pernah_trx
FROM users
WHERE user_id
NOT IN (SELECT
  buyer_id
FROM orders)
AND user_id
NOT IN (SELECT
  seller_id
FROM orders);

-- Top Buyer All Time
SELECT
  buyer_id,
  nama_user,
  SUM(total) AS total_transaksi
FROM orders AS o
JOIN users AS u
  ON o.buyer_id = u.user_id
GROUP BY 1, 2
ORDER BY 3 DESC LIMIT 5;

-- Frequent Buyer
SELECT
  buyer_id,
  nama_user,
  COUNT(order_id) AS jumlah_transaksi
FROM orders AS o
JOIN users AS u
  ON o.buyer_id = u.user_id
WHERE discount = 0
GROUP BY 1, 2
ORDER BY 3 DESC LIMIT 5;

-- Big Frequent Buyer 2020
SELECT
  buyer_id,
  email,
  rata_rata,
  month_count
FROM (SELECT
  trx.buyer_id,
  rata_rata,
  jumlah_order,
  month_count
FROM (SELECT
  buyer_id,
  ROUND(AVG(total), 2) AS rata_rata
FROM orders
WHERE DATE_FORMAT(created_at, '%Y') = '2020'
GROUP BY 1
HAVING rata_rata > 1000000
ORDER BY 1) AS trx
JOIN (SELECT
  buyer_id,
  COUNT(order_id) AS jumlah_order,
  COUNT(DISTINCT DATE_FORMAT(created_at, '%m')) AS month_count
FROM orders
WHERE DATE_FORMAT(created_at, '%Y') = '2020'
GROUP BY 1
HAVING month_count >= 5
AND jumlah_order >= month_count
ORDER BY 1) AS months
  ON trx.buyer_id = months.buyer_id) AS bfq
JOIN users
  ON buyer_id = user_id
ORDER BY 3 DESC;
    
 -- Domain email dari penjual 
SELECT
DISTINCT
  substr(email, instr(email, '@') + 1) AS domain_email,
  COUNT(user_id) AS jumlah_pengguna_seller
FROM users
WHERE user_id IN (SELECT
  seller_id
FROM orders)
GROUP BY 1
ORDER BY 2 DESC;

-- Top 5 Product Desember 2019
SELECT
  SUM(quantity) AS total_quantity,
  desc_product
FROM order_details od
JOIN products p
  ON od.product_id = p.product_id
JOIN orders o
  ON od.order_id = o.order_id
WHERE created_at BETWEEN '2019-12-01' AND '2019-12-31'
GROUP BY 2
ORDER BY 1 DESC LIMIT 5;


-- 10 Transaksi terbesar user 12476
SELECT
  seller_id,
  buyer_id,
  total AS nilai_transaksi,
  created_at AS tanggal_transaksi
FROM orders
WHERE buyer_id = 12476
ORDER BY 3 DESC LIMIT 10;

-- Transaksi per bulan 2020
SELECT
  EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan,
  count(1) AS jumlah_transaksi,
  sum(total) AS total_nilai_transaksi
FROM orders
WHERE created_at >= '2020-01-01'
GROUP BY 1
ORDER BY 1;

-- Pengguna dengan rata-rata transaksi terbesar di Januari 2020
SELECT
  buyer_id,
  COUNT(1) AS jumlah_transaksi,
  AVG(total) AS avg_nilai_transaksi
FROM orders
WHERE created_at >= '2020-01-01'
AND created_at < '2020-02-01'
GROUP BY 1
HAVING COUNT(1) >= 2
ORDER BY 3 DESC LIMIT 10;

-- Transaksi besar di Desember 2019
SELECT
  nama_user AS nama_pembeli,
  total AS nilai_transaksi,
  created_at AS tanggal_transaksi
FROM orders
INNER JOIN users
  ON buyer_id = user_id
WHERE created_at >= '2019-12-01'
AND created_at < '2020-01-01'
AND total >= 20000000
ORDER BY 1;

-- Kategori Produk Terlaris di 2020
SELECT
  category,
  sum(quantity) AS total_quantity,
  sum(price) AS total_price
FROM orders
INNER JOIN order_details
  USING(order_id)
INNER JOIN products
  USING(product_id)
WHERE
  created_at >= '2020-01-01' AND delivery_at IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC LIMIT 5;

-- Pembeli High Value
SELECT
  nama_user AS nama_pembeli,
  COUNT(1) AS jumlah_transaksi,
  SUM(total) AS total_nilai_transaksi,
  MIN(total) AS min_nilai_transaksi
FROM orders
INNER JOIN users
  ON buyer_id = user_id
GROUP BY user_id,
         nama_user
HAVING COUNT(1) > 5 
AND MIN(total) > 2000000
ORDER BY 3 DESC;

-- Mencari Dropshipper
SELECT
  nama_user AS nama_pembeli,
  COUNT(1) AS jumlah_transaksi,
  COUNT(DISTINCT orders.kodepos) AS distinct_kodepos,
  SUM(total) AS total_nilai_transaksi,
  AVG(total) AS avg_nilai_transaksi
FROM orders
INNER JOIN users
  ON buyer_id = user_id
GROUP BY user_id,
         nama_user
HAVING COUNT(1) >= 10
AND COUNT(1) = COUNT(DISTINCT orders.kodepos)
ORDER BY 2 DESC;

-- Mencari Dropshipper
SELECT
   nama_user as nama_pembeli,
   count(1) as jumlah_transaksi, 
   sum(total) as total_nilai_transaksi, 
   avg(total) as avg_nilai_transaksi,
   avg(total_quantity) as avg_quantity_per_transaksi
FROM orders 
INNER JOIN users ON buyer_id = user_id 
INNER JOIN (select order_id, sum(quantity) as total_quantity from order_details group by 1) as summary_order using(order_id)
WHERE orders.kodepos=users.kodepos
GROUP BY user_id, nama_user
HAVING count(1)>= 8 AND avg(total_quantity)>10
ORDER BY 3 DESC;

-- Pembeli sekaligus penjual
SELECT
  nama_user AS nama_pengguna,
  jumlah_transaksi_beli,
  jumlah_transaksi_jual
FROM users
INNER JOIN (SELECT
  buyer_id,
  COUNT(1) AS jumlah_transaksi_beli
FROM orders
GROUP BY 1) AS buyer
  ON buyer_id = user_id
INNER JOIN (SELECT
  seller_id,
  COUNT(1) AS jumlah_transaksi_jual
FROM orders
GROUP BY 1) AS seller
  ON seller_id = user_id
WHERE jumlah_transaksi_beli >= 7
ORDER BY 1;

-- Lama transaksi dibayar
SELECT
	EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan,
	COUNT(1) AS jumlah_transaksi,
	AVG(datediff(paid_at,created_at)) AS avg_lama_dibayar,
	MIN(datediff(paid_at,created_at)) min_lama_dibayar,
	MAX(datediff(paid_at,created_at)) max_lama_dibayar
FROM orders 
WHERE paid_at IS NOT NULL 
GROUP BY 1 
ORDER BY 1;