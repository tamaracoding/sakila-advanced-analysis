
-- SAKILA PRACTICE
show tables;
select * from actor;
select * from actor_info;
select * from address;
select * from category;
select * from city;
select * from country;
select * from customer;
select * from customer_list;
select * from film;
select * from film_actor;
select * from film_category;
select * from film_text;
select * from inventory;
select * from language;
select * from nicer_but_slower_film_list;
select * from payment;
select * from rental;
select * from sales_by_film_category;
select * from sales_by_store;
select * from staff;
select * from staff_list;
select * from store;

-- Cari 5 pelanggan dengan jumlah transaksi tertinggi sepanjang masa.
-- Sertakan nama pelanggan, total transaksi, dan rata-rata nilai transaksi mereka.
select * from payment;
select * from customer;

select concat(c.first_name,' ',c.last_name) full_name, sum(p.amount) total_transaksi, avg(p.amount) rata2_transaksi
from customer c join payment p on c.customer_id = p.customer_id
group by full_name
order by total_transaksi desc
limit 5;

-- Untuk setiap kategori film, hitung total pendapatan yang dihasilkan, rata-rata durasi film, total transaksi, dan jumlah pelanggan
-- Urutkan kategori berdasarkan total pendapatan tertinggi.
select * from category;
select * from film_category;
select * from film;
select * from payment;
select * from rental;
select * from inventory;

select
	c.name,
    sum(p.amount) total_pendapatan,
    avg(f.length) rata2_durasi_film,
    count(p.payment_id) total_transaksi,
    count(distinct p.customer_id) total_cust
from category c join film_category fc
	on c.category_id = fc.category_id
join film f
	on fc.film_id = f.film_id
join inventory i
	on fc.film_id = i.film_id
join rental r
	on i.inventory_id = r.inventory_id
join payment p
	on r.rental_id =  p.rental_id
group by c.name
order by total_pendapatan desc;

-- Temukan jam berapa (dalam 24 jam) rental paling sering dilakukan.
-- Tampilkan jam tersebut dan jumlah transaksi yang dilakukan pada jam tersebut.
select * from rental;

select count(rental_id) jumlah_transaksi, hour(rental_date) jam_sewa
from rental
group by jam_sewa
order by jumlah_transaksi desc;

-- Hitung persentase pelanggan aktif (pelanggan yang melakukan setidaknya 1 transaksi) dibandingkan dengan total pelanggan dalam database.
select * from customer;

select (count(customer_id)*100 / (select count(customer_id) from customer)) persentase_cust_aktif
from customer
where active = 1;

-- Berapa persentase film di inventaris yang pernah dirental setidaknya satu kali?
-- Sertakan jumlah film yang pernah dirental dan total film di inventaris.
select * from inventory;
select * from rental;

select
	concat(round(count(distinct r.inventory_id)*100/
	(select count(i.inventory_id) from inventory i),2),'%') persentase_film_disewa,
(select count(distinct r.inventory_id) from rental r) jumlah_film_disewa,
(select count(distinct i.inventory_id) from inventory i) jumlah_film_inventaris
from rental r;

-- Cari 5 kota dengan pendapatan rental tertinggi.
-- Tampilkan nama kota, negara, dan total pendapatan rental dari setiap kota.
select * from city;
select * from country;
select * from address;
select * from customer;
select * from payment;

select ci.city, co.country, sum(p.amount) total_pendapatan
from city ci join country co
	on ci.country_id = co.country_id
join address a
	on ci.city_id = a.city_id
join customer c
	on a.address_id = c.address_id
join payment p
	on c.customer_id = p.customer_id
group by ci.city, co.country
order by total_pendapatan desc
limit 5;

-- Analisis rata-rata durasi keterlambatan pengembalian sewa film.
-- Cari customer yang paling sering terlambat melakukan pengembalian:

select * from film;
select * from rental;
select * from payment;
select * from inventory;

-- Virtual tabel untuk data keterlambatan pengembalian film

create or replace view tabel_keterlambatan as
(select
	f.film_id,
    r.customer_id,
    f.title,
    f.rental_duration as durasi_sewa_awal, 
    date(r.rental_date) as rental_date, 
    date(r.return_date) as return_date,
    datediff(r.return_date, r.rental_date) as durasi_sewa_sebenarnya,
    case
        when datediff(r.return_date, r.rental_date) > f.rental_duration then 1
        when r.return_date is null then 1
        else 0
    end as terlambat,
    case
        when datediff(r.return_date, r.rental_date) > f.rental_duration 
        then datediff(r.return_date, r.rental_date) - f.rental_duration
        else 0
    end as lama_keterlambatan,
    p.amount,
    f.rental_rate,
    p.amount - f.rental_rate as denda_keterlambatan
from 
    payment p 
join 
    rental r on p.rental_id = r.rental_id
join 
    inventory i on r.inventory_id = i.inventory_id
join 
    film f on i.film_id = f.film_id);

-- Durasi keterlambatan rata-rata:
select avg(lama_keterlambatan) from tabel_keterlambatan
where terlambat = 1;

-- Customer yang paling sering terlambat melakukan pengembalian film:
select
	tk.customer_id,
    concat(c.first_name,' ',c.last_name) nama_lengkap,
    count(tk.terlambat) frekuensi_terlambat
from tabel_keterlambatan tk join customer c on tk.customer_id = c.customer_id
where terlambat = 1
group by customer_id
order by frekuensi_terlambat desc;

-- Hitung rata-rata jumlah transaksi per pelanggan untuk setiap negara.
-- Urutkan negara berdasarkan rata-rata transaksi per pelanggan, dari yang tertinggi ke terendah.
select * from city;
select * from country;
select * from address;
select * from customer;
select * from payment;

select country, round(avg(jumlah_transaksi),1) rata_rata_jumlah_transaksi
from
(select
	c.customer_id,
    co.country,
    count(p.payment_id) jumlah_transaksi
from country co join city ci
	on co.country_id = ci.country_id
join address a
	on ci.city_id = a.city_id
join customer c
	on a.address_id = c.address_id
join payment p
	on c.customer_id = p.customer_id
group by 1,2) as jumlah_transaksi_per_cust
group by 1
order by 2 desc;

-- Untuk setiap staf, hitung total pendapatan rental yang dihasilkan.
-- Urutkan staf berdasarkan total pendapatan dari transaksi yang mereka proses.
select * from staff;
select * from payment;
select
	concat(s.first_name,' ', s.last_name) nama_lengkap_staff,
    sum(p.amount) omset
from staff s join payment p
	on s.staff_id = p.staff_id
group by 1
order by 2 desc;

-- Analisis tren popularitas sebuah film berdasarkan jumlah rental-nya per bulan.
-- Tampilkan hasil untuk salah satu film dengan jumlah rental tertinggi.

select * from film;
select * from inventory;
select * from rental;

with jumlah_sewa_per_judul as
(select
	f.film_id,
	f.title,
    count(r.rental_id) jumlah_sewa
from rental r join inventory i
	on r.inventory_id = i.inventory_id
join film f 
	on i.film_id = f.film_id
group by 1,2
order by 3 desc
limit 1),

sewa_per_bulan as
(select
	f.title,
    month(r.rental_date) bulan_sewa,
    year(r.rental_date) tahun_sewa,
    count(r.rental_id) jumlah_sewa
from rental r join inventory i
	on r.inventory_id = i.inventory_id
join film f 
	on i.film_id = f.film_id
where f.film_id = (select film_id from jumlah_sewa_per_judul)
group by 1,2,3
)

select * from sewa_per_bulan;

-- Top 5 Film yang paling banyak disewa setiap bulan, berdasarkan jumlah penyewaan
with monthly_rank as
(select
	f.title,
    count(r.rental_id) jumlah_sewa,
    month(r.rental_date) bulan_sewa,
    row_number()over(partition by month(r.rental_date) order by count(r.rental_id) desc) as peringkat_sewa_terbanyak
from rental r join inventory i
	on r.inventory_id = i.inventory_id
join film f 
	on i.film_id = f.film_id
group by 1,3
order by 2 desc)

select title, jumlah_sewa, bulan_sewa
from monthly_rank
where peringkat_sewa_terbanyak between 1 and 5;