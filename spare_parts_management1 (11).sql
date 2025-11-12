-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : lun. 08 sep. 2025 à 20:08
-- Version du serveur : 10.4.28-MariaDB
-- Version de PHP : 8.1.17

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `spare_parts_management1`
--

-- --------------------------------------------------------

--
-- Structure de la table `credit_payments`
--

CREATE TABLE `credit_payments` (
  `id` int(11) NOT NULL,
  `credit_sale_id` int(11) NOT NULL,
  `received_by` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_date` date NOT NULL,
  `payment_method` enum('cash','check','bank_transfer') DEFAULT 'cash',
  `reference_number` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `credit_payments`
--

INSERT INTO `credit_payments` (`id`, `credit_sale_id`, `received_by`, `amount`, `payment_date`, `payment_method`, `reference_number`, `notes`, `created_at`) VALUES
(78, 585, 43, 50.00, '2025-08-27', 'cash', NULL, '', '2025-08-27 15:19:36'),
(79, 585, 43, 50.00, '2025-08-27', 'cash', NULL, '', '2025-08-27 15:19:41'),
(80, 586, 1000, 60.00, '2025-08-27', 'cash', NULL, '', '2025-08-27 15:46:46'),
(81, 586, 1000, 300.00, '2025-08-27', 'cash', NULL, '', '2025-08-27 15:46:51'),
(82, 589, 1000, 18.00, '2025-09-04', 'cash', NULL, '', '2025-09-04 11:33:48'),
(83, 590, 1000, 30.00, '2025-09-08', 'cash', NULL, '', '2025-09-08 17:02:30'),
(84, 590, 1000, 6.00, '2025-09-08', 'cash', NULL, '', '2025-09-08 17:02:38');

-- --------------------------------------------------------

--
-- Structure de la table `credit_sales`
--

CREATE TABLE `credit_sales` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `warehouse_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `sale_date` date NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `down_payment` decimal(10,2) NOT NULL,
  `credit_amount` decimal(10,2) NOT NULL,
  `installment_count` int(11) NOT NULL,
  `monthly_payment` decimal(10,2) NOT NULL,
  `first_payment_date` date NOT NULL,
  `last_payment_date` date DEFAULT NULL,
  `status` enum('pending','active','completed','overdue') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `credit_sales`
--

INSERT INTO `credit_sales` (`id`, `customer_id`, `warehouse_id`, `created_by`, `sale_date`, `total_amount`, `down_payment`, `credit_amount`, `installment_count`, `monthly_payment`, `first_payment_date`, `last_payment_date`, `status`, `notes`, `createdAt`) VALUES
(585, 1, 1, 43, '2025-08-27', 100.00, 0.00, 100.00, 1, 100.00, '2025-09-26', NULL, 'completed', '', '2025-08-27 15:19:26'),
(586, 1013, 1, 1000, '2025-08-27', 360.00, 0.00, 360.00, 1, 360.00, '2025-09-26', NULL, 'completed', '', '2025-08-27 15:46:31'),
(587, 1010, 1, 43, '2025-09-03', 18.00, 0.00, 18.00, 1, 18.00, '2025-10-03', NULL, 'active', '', '2025-09-03 16:36:23'),
(588, 1009, 1, 43, '2025-09-03', 18.00, 0.00, 18.00, 1, 18.00, '2025-10-03', NULL, 'active', '', '2025-09-03 16:47:26'),
(589, 1, 1, 1000, '2025-09-04', 18.00, 0.00, 18.00, 1, 18.00, '2025-10-04', NULL, 'completed', '', '2025-09-04 11:33:28'),
(590, 1011, 1, 1000, '2025-09-08', 36.00, 0.00, 36.00, 1, 36.00, '2025-10-08', NULL, 'completed', '', '2025-09-08 17:02:10');

-- --------------------------------------------------------

--
-- Structure de la table `credit_sale_items`
--

CREATE TABLE `credit_sale_items` (
  `id` int(11) NOT NULL,
  `credit_sale_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `credit_sale_items`
--

INSERT INTO `credit_sale_items` (`id`, `credit_sale_id`, `product_id`, `quantity`, `unit_price`, `total_price`) VALUES
(82, 585, 2, 10, 10.00, 100.00),
(83, 586, 1, 20, 18.00, 360.00),
(84, 587, 1, 1, 18.00, 18.00),
(85, 588, 1, 1, 18.00, 18.00),
(86, 589, 1, 1, 18.00, 18.00),
(87, 590, 1, 2, 18.00, 36.00);

-- --------------------------------------------------------

--
-- Structure de la table `customers`
--

CREATE TABLE `customers` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone_number` varchar(20) NOT NULL,
  `address` text DEFAULT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `tax_number` varchar(50) DEFAULT NULL,
  `credit_limit` decimal(10,2) DEFAULT 0.00,
  `current_balance` decimal(10,2) DEFAULT 0.00,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_credit_authorized` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `customers`
--

INSERT INTO `customers` (`id`, `name`, `email`, `phone_number`, `address`, `company_name`, `tax_number`, `credit_limit`, `current_balance`, `is_active`, `created_at`, `updated_at`, `is_credit_authorized`) VALUES
(1, 'basem', 'basem@esprit.tn', '20188615', 'sokra', NULL, NULL, 0.00, 0.04, 1, '2025-07-30 23:50:53', '2025-08-27 15:19:41', 0),
(2, 'Test Customer', NULL, '', NULL, NULL, NULL, 0.00, 0.00, 0, '2025-08-09 17:26:51', '2025-08-13 15:44:26', 0),
(4, 'Test Customer', 'testcustomer@example.com', '9876543210', '123 Main St', 'Test Company Ltd', 'TX123456', 5000.00, 0.00, 1, '2025-08-09 17:29:02', '2025-08-25 15:03:29', 1),
(999, 'Test Customer', 'testcustomer999@example.com', '987654321', 'Test Address', NULL, NULL, 0.00, 0.00, 1, '2025-08-09 17:42:51', '2025-08-13 17:29:53', 0),
(1006, 'riadh', 'riadh@SNR.tn', '45123562', 'soukra', NULL, NULL, 0.00, 0.00, 1, '2025-08-13 15:15:00', '2025-08-22 17:08:32', 0),
(1007, 'semah', 'semah@gmail.com', '45623147', 'wed elil', NULL, NULL, 0.00, 0.01, 1, '2025-08-13 15:50:57', '2025-08-27 15:12:24', 0),
(1008, 'maram', 'maram@gmail.com', '23564789', 'riadh', NULL, NULL, 0.00, 0.01, 1, '2025-08-13 17:13:23', '2025-08-27 15:06:20', 0),
(1009, 'chaabi', 'azizchabi@gmail.com', '92926234', 'soukra', NULL, NULL, 0.00, 0.00, 1, '2025-08-13 17:23:07', '2025-08-27 15:09:31', 0),
(1010, 'anwar', 'anwar@gmail.com', '451235456', 'nabel', NULL, NULL, 0.00, 0.03, 1, '2025-08-13 17:26:42', '2025-08-27 15:04:08', 0),
(1011, 'nadhem', 'nadhem@gmail.com', '52456789', NULL, NULL, NULL, 0.00, 0.01, 1, '2025-08-21 11:45:26', '2025-08-25 15:01:30', 0),
(1012, 'salah', 'mohamedsalah.bedoui@esprit.tn', '54506437', 'sokra', NULL, NULL, 0.00, 0.01, 1, '2025-08-25 15:07:34', '2025-08-25 15:09:10', 0),
(1013, 'mariem', NULL, '45555555', NULL, NULL, NULL, 0.00, 0.00, 1, '2025-08-27 15:44:10', '2025-08-27 15:46:51', 0);

-- --------------------------------------------------------

--
-- Structure de la table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(11) NOT NULL,
  `timestamp` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `migrations`
--

INSERT INTO `migrations` (`id`, `timestamp`, `name`) VALUES
(1, 1700000000000, 'InitialSchema1700000000000'),
(2, 1753561352380, 'AddProductCategory1753561352380'),
(3, 1753561626161, 'AddMissingColumns1753561626161'),
(4, 1753561626161, 'AddMissingColumns1753561626161');

-- --------------------------------------------------------

--
-- Structure de la table `operational_expenses`
--

CREATE TABLE `operational_expenses` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `type` enum('rent','electricity','water','fuel','other') NOT NULL,
  `warehouse_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `date` date NOT NULL,
  `note` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `operational_expenses`
--

INSERT INTO `operational_expenses` (`id`, `title`, `amount`, `type`, `warehouse_id`, `created_by`, `date`, `note`) VALUES
(1, 'steg', 1900.00, 'electricity', 1, 35, '2025-08-09', 'ee'),
(2, 'pop', 8000.00, 'electricity', 3, 35, '2025-08-09', 'oo'),
(8, 'test', 5000.00, 'water', 1, 43, '2025-08-27', 'rrrr'),
(9, 'test', 500.00, 'electricity', 1, 1000, '2025-08-27', 'xxx'),
(10, 'RR', 11.00, 'electricity', 1, 1000, '2025-09-04', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `otp`
--

CREATE TABLE `otp` (
  `id` int(11) NOT NULL,
  `otp` varchar(255) NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `otpExpires` datetime NOT NULL,
  `createdAt` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `name` varchar(255) NOT NULL,
  `reference_code` varchar(255) NOT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `supplier_price` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `products`
--

INSERT INTO `products` (`id`, `description`, `unit_price`, `name`, `reference_code`, `brand`, `category`, `image`, `supplier_id`, `supplier_price`) VALUES
(1, 'AS YA BATIKHA', 18.00, 'Filtre à huile', '12457896', 'Bosch', 'Automobile', 'http://localhost:3000/uploads/1753750343928-992578763.webp', 1, 12.00),
(2, 'Roulement à billes pour moteur ou transmission', 10.00, 'Roulement 6202', 'BP-12345', 'SKF', 'Industrielle', '1753732149436-999850085.jpg', 1, 6.00),
(4, 'Vérin simple effet 40 bars, usage industriel', 220.00, 'Vérin hydraulique', 'BB-12345', 'Parker', 'Industrielle', '1753645790783-83630319.jpg', 1, 150.00),
(26, 'test', 10.00, 'test', 'test', 'test', 'test', '1753919882344-627834643.webp', 1, 5.00),
(27, 'saga', 120.00, 'as', '78945632', 'BOSCH', 'ELECTRONICS', '1756926477476-784316652.webp', 1, 99.00);

-- --------------------------------------------------------

--
-- Structure de la table `product_stocks`
--

CREATE TABLE `product_stocks` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `warehouse_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `product_stocks`
--

INSERT INTO `product_stocks` (`id`, `product_id`, `warehouse_id`, `quantity`) VALUES
(12, 1, 1, 27),
(13, 2, 1, 182),
(14, 4, 1, 101),
(15, 1, 2, 14),
(16, 4, 2, 78),
(17, 2, 2, 95);

-- --------------------------------------------------------

--
-- Structure de la table `product_transfers`
--

CREATE TABLE `product_transfers` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `from_warehouse_id` int(11) NOT NULL,
  `to_warehouse_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal',
  `status` enum('pending','approved','rejected','in_transit','completed','cancelled') DEFAULT 'pending',
  `reason` text NOT NULL,
  `notes` text DEFAULT NULL,
  `requested_by` int(11) NOT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `approved_at` timestamp NULL DEFAULT NULL,
  `processed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `product_transfers`
--

INSERT INTO `product_transfers` (`id`, `product_id`, `from_warehouse_id`, `to_warehouse_id`, `quantity`, `priority`, `status`, `reason`, `notes`, `requested_by`, `approved_by`, `processed_by`, `created_at`, `updated_at`, `approved_at`, `processed_at`) VALUES
(1, 1, 1, 2, 1, 'normal', 'approved', 'xx', 'xx', 1000, 1000, NULL, '2025-09-08 17:19:53', '2025-09-08 17:45:55', '2025-09-08 17:45:55', NULL),
(2, 1, 1, 2, 2, 'normal', 'approved', 'xx', 'xx', 1000, 1000, NULL, '2025-09-08 17:20:28', '2025-09-08 17:42:02', '2025-09-08 17:42:02', NULL),
(3, 1, 1, 2, 4, 'normal', 'in_transit', 'xx', 'xx', 1000, 1000, 1000, '2025-09-08 17:23:42', '2025-09-08 18:01:49', '2025-09-08 17:41:48', '2025-09-08 18:01:49'),
(4, 1, 1, 2, 10, 'normal', 'completed', 'xx', 'xx', 1000, 1000, 1000, '2025-09-08 17:51:37', '2025-09-08 17:54:08', '2025-09-08 17:54:08', '2025-09-08 17:54:08'),
(5, 4, 2, 1, 20, 'normal', 'completed', 'xx', 'xx', 1000, 1000, 1000, '2025-09-08 18:00:47', '2025-09-08 18:00:49', '2025-09-08 18:00:49', '2025-09-08 18:00:49'),
(6, 4, 2, 1, 1, 'urgent', 'completed', 'x', 'x', 1000, 1000, 1000, '2025-09-08 18:05:43', '2025-09-08 18:05:48', '2025-09-08 18:05:48', '2025-09-08 18:05:48');

-- --------------------------------------------------------

--
-- Structure de la table `purchases`
--

CREATE TABLE `purchases` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `created_by` int(11) NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  `delivered_by` varchar(255) DEFAULT NULL,
  `deliveredAt` datetime DEFAULT NULL,
  `credit_applied` decimal(10,2) NOT NULL DEFAULT 0.00,
  `final_amount` decimal(10,2) GENERATED ALWAYS AS (`total_amount` - `credit_applied`) STORED
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `purchases`
--

INSERT INTO `purchases` (`id`, `supplier_id`, `date`, `total_amount`, `created_by`, `status`, `delivered_by`, `deliveredAt`, `credit_applied`) VALUES
(17, 1, '2025-08-01', 1200.00, 40, 'delivered', '42', '2025-08-01 19:36:07', 0.00),
(18, 1, '2025-08-01', 1200.00, 40, 'delivered', '40', '2025-09-03 14:04:06', 0.00),
(19, 1, '2025-08-01', 3000.00, 40, 'pending', NULL, NULL, 0.00),
(20, 1, '2025-08-01', 800.00, 40, 'pending', NULL, NULL, 0.00),
(21, 1, '2025-08-01', 800.00, 40, 'pending', NULL, NULL, 0.00),
(22, 1, '2025-08-01', 800.00, 40, 'pending', NULL, NULL, 0.00),
(23, 1, '2025-08-01', 1464.00, 40, 'pending', NULL, NULL, 0.00),
(24, 1, '2025-08-01', 1464.00, 40, 'pending', NULL, NULL, 0.00),
(25, 1, '2025-08-01', 12.00, 40, 'pending', NULL, NULL, 0.00),
(26, 1, '2025-08-01', 1332.00, 40, 'pending', NULL, NULL, 0.00),
(27, 1, '2025-08-01', 1332.00, 40, 'pending', NULL, NULL, 0.00),
(28, 2, '2025-08-01', 1344.00, 40, 'pending', NULL, NULL, 0.00),
(29, 1, '2025-08-14', 1500.00, 40, 'delivered', '42', '2025-08-14 18:21:47', 0.00),
(30, 1, '2025-08-14', 1500.00, 40, 'delivered', '42', '2025-08-14 18:58:21', 60.00),
(37, 1, '2025-07-30', 1200.00, 35, 'delivered', '40', '2025-08-01 19:47:53', 0.00),
(38, 1, '2025-08-13', 600.00, 35, 'delivered', '43', '2025-08-13 15:01:33', 0.00),
(39, 1, '2025-08-13', 600.00, 35, 'delivered', '43', '2025-08-13 15:20:53', 0.00),
(40, 1, '2025-08-13', 15000.00, 35, 'delivered', '43', '2025-08-13 15:20:55', 0.00),
(41, 1, '2025-08-13', 228.00, 35, 'delivered', '1001', '2025-08-13 19:55:37', 0.00),
(42, 1, '2025-08-13', 120.00, 35, 'delivered', '1001', '2025-08-13 19:55:49', 0.00),
(43, 1, '2025-08-13', 120.00, 35, 'delivered', '1001', '2025-08-13 19:55:52', 0.00),
(44, 1, '2025-08-13', 300.00, 35, 'delivered', '1001', '2025-08-13 19:55:55', 0.00),
(45, 1, '2025-08-13', 1500.00, 35, 'delivered', '43', '2025-08-13 16:01:32', 0.00),
(46, 1, '2025-08-13', 1200.00, 35, 'delivered', '43', '2025-08-13 16:35:50', 0.00),
(47, 2, '2025-08-13', 15000.00, 35, 'delivered', '43', '2025-08-13 19:49:25', 0.00),
(48, 2, '2025-08-13', 600.00, 1002, 'delivered', '1001', '2025-08-13 20:06:58', 0.00),
(49, 1, '2025-08-27', 1200.00, 1003, 'delivered', '1001', '2025-08-27 16:43:14', 0.00),
(50, 2, '2025-09-04', 762.00, 1002, 'delivered', '1001', '2025-09-04 02:25:12', 0.00);

-- --------------------------------------------------------

--
-- Structure de la table `purchase_items`
--

CREATE TABLE `purchase_items` (
  `id` int(11) NOT NULL,
  `purchase_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `warehouse_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `purchase_items`
--

INSERT INTO `purchase_items` (`id`, `purchase_id`, `product_id`, `quantity`, `unit_price`, `warehouse_id`) VALUES
(1, 29, 26, 50, 30.00, 1),
(2, 30, 26, 50, 30.00, 1),
(28, 37, 1, 100, 12.00, 1),
(29, 38, 2, 100, 6.00, 1),
(30, 39, 2, 100, 6.00, 1),
(31, 40, 4, 100, 150.00, 1),
(32, 41, 1, 19, 12.00, 1),
(33, 42, 1, 10, 12.00, 1),
(34, 43, 2, 20, 6.00, 1),
(35, 44, 4, 2, 150.00, 1),
(36, 45, 4, 10, 150.00, 1),
(37, 46, 1, 100, 12.00, 2),
(38, 47, 4, 100, 150.00, 2),
(39, 48, 2, 100, 6.00, 2),
(40, 49, 1, 100, 12.00, 1),
(41, 50, 2, 100, 6.00, 1),
(42, 50, 4, 1, 150.00, 2),
(43, 50, 1, 1, 12.00, 1);

-- --------------------------------------------------------

--
-- Structure de la table `purchase_returns`
--

CREATE TABLE `purchase_returns` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `warehouse_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `return_date` date NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `reason` text DEFAULT NULL,
  `status` enum('pending','approved','rejected','completed') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp(6) NOT NULL DEFAULT current_timestamp(6),
  `updated_at` timestamp(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `purchase_returns`
--

INSERT INTO `purchase_returns` (`id`, `supplier_id`, `warehouse_id`, `created_by`, `return_date`, `total_amount`, `reason`, `status`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 13, '2025-08-23', 500.00, 'Produit endommagé', 'pending', 'À vérifier par le manager', '2025-08-23 19:38:29.568392', '2025-08-23 19:38:29.568392'),
(2, 2, 2, 17, '2025-08-22', 1200.50, 'Erreur de livraison', 'approved', 'Validé par le manager', '2025-08-23 19:38:29.568392', '2025-08-23 19:38:29.568392'),
(3, 3, 3, 35, '2025-08-21', 300.75, 'Produit non conforme', 'rejected', 'Retour refusé', '2025-08-23 19:38:29.568392', '2025-08-23 19:38:29.568392'),
(4, 1, 4, 36, '2025-08-20', 450.00, 'Stock excédentaire', 'completed', 'Retour finalisé', '2025-08-23 19:38:29.568392', '2025-08-23 19:38:29.568392'),
(8, 1, 1, 40, '2025-08-14', 60.00, 'defected', 'completed', NULL, '2025-08-14 17:57:02.000000', '2025-08-14 18:18:08.000000'),
(9, 1, 1, 40, '2025-08-14', 300.00, 'defected', 'completed', NULL, '2025-08-14 18:47:51.000000', '2025-08-14 19:01:00.000000'),
(10, 1, 1, 40, '2025-08-14', 600.00, 'defected', 'completed', NULL, '2025-08-14 18:59:58.000000', '2025-08-14 19:01:04.000000'),
(11, 1, 1, 40, '2025-08-14', 12.00, 'fgh', 'pending', NULL, '2025-08-14 19:12:44.000000', '2025-08-14 19:12:44.000000'),
(12, 1, 1, 40, '2025-08-14', 12.00, 'aaabb', 'pending', NULL, '2025-08-14 19:18:33.000000', '2025-08-14 19:18:33.000000'),
(13, 1, 1, 40, '2025-08-14', 12.00, '123', 'pending', NULL, '2025-08-14 19:21:52.000000', '2025-08-14 19:21:52.000000'),
(14, 1, 1, 40, '2025-08-14', 12.00, 'aze', 'pending', NULL, '2025-08-14 19:25:56.000000', '2025-08-14 19:25:56.000000'),
(15, 1, 1, 40, '2025-08-14', 50.99, 'azertyui', 'pending', NULL, '2025-08-14 19:29:01.000000', '2025-08-14 19:29:01.000000'),
(16, 1, 1, 40, '2025-08-14', 12.00, 'aze', 'pending', NULL, '2025-08-14 19:31:52.000000', '2025-08-14 19:31:52.000000'),
(17, 1, 1, 40, '2025-08-14', 12.00, 'ghj', 'pending', NULL, '2025-08-14 19:35:26.000000', '2025-08-14 19:35:26.000000'),
(18, 1, 1, 40, '2025-08-14', 12.00, 'aze', 'pending', NULL, '2025-08-14 19:38:35.000000', '2025-08-14 19:38:35.000000'),
(19, 1, 1, 40, '2025-08-19', 1200.00, 'hh', 'approved', NULL, '2025-08-19 14:22:12.000000', '2025-08-19 14:25:49.000000'),
(20, 1, 1, 40, '2025-08-25', 120.00, 'azerrrrr', 'pending', NULL, '2025-08-25 15:11:28.000000', '2025-08-25 15:11:28.000000'),
(21, 1, 1, 40, '2025-08-25', 132.00, '124hh', 'pending', NULL, '2025-08-25 15:17:51.000000', '2025-08-25 15:17:51.000000'),
(22, 1, 1, 41, '2025-08-26', 12.00, 'aze', 'approved', NULL, '2025-08-26 16:23:47.000000', '2025-08-26 16:24:29.000000'),
(23, 1, 1, 41, '2025-08-26', 12.00, 'oo', 'pending', 'ii', '2025-08-26 16:52:33.000000', '2025-08-26 16:52:33.000000'),
(24, 1, 1, 41, '2025-08-26', 12.00, '2', 'pending', NULL, '2025-08-26 16:54:20.000000', '2025-08-26 16:54:20.000000'),
(25, 1, 1, 41, '2025-08-26', 12.00, 'za', 'pending', NULL, '2025-08-26 16:55:14.000000', '2025-08-26 16:55:14.000000'),
(26, 1, 1, 41, '2025-08-26', 12.00, '123', 'pending', NULL, '2025-08-26 16:59:04.000000', '2025-08-26 16:59:04.000000'),
(27, 1, 1, 41, '2025-08-26', 24.00, 'PP', 'pending', NULL, '2025-08-26 17:23:27.000000', '2025-08-26 17:23:27.000000'),
(28, 1, 1, 41, '2025-08-26', 12.00, 'EE', 'pending', NULL, '2025-08-26 17:24:26.000000', '2025-08-26 17:24:26.000000'),
(29, 1, 1, 41, '2025-08-26', 144.00, 'EEE', 'approved', 'EEE', '2025-08-26 17:24:44.000000', '2025-08-26 17:24:50.000000'),
(30, 1, 1, 41, '2025-08-26', 12.00, 'to', 'approved', NULL, '2025-08-26 17:33:45.000000', '2025-08-26 17:33:56.000000');

-- --------------------------------------------------------

--
-- Structure de la table `purchase_return_items`
--

CREATE TABLE `purchase_return_items` (
  `id` int(11) NOT NULL,
  `purchase_return_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `purchase_return_items`
--

INSERT INTO `purchase_return_items` (`id`, `purchase_return_id`, `product_id`, `quantity`, `unit_price`, `total_price`) VALUES
(6, 1, 1, 5, 50.00, 250.00),
(7, 1, 2, 2, 75.00, 150.00),
(8, 2, 4, 10, 120.00, 1200.00),
(7, 8, 26, 2, 30.00, 60.00),
(8, 8, 26, 2, 30.00, 60.00),
(9, 9, 26, 10, 30.00, 300.00),
(10, 9, 26, 10, 30.00, 300.00),
(11, 10, 1, 50, 12.00, 600.00),
(12, 10, 1, 50, 12.00, 600.00),
(13, 11, 1, 1, 12.00, 12.00),
(14, 11, 1, 1, 12.00, 12.00),
(15, 12, 1, 1, 12.00, 12.00),
(16, 12, 1, 1, 12.00, 12.00),
(17, 13, 1, 1, 12.00, 12.00),
(18, 13, 1, 1, 12.00, 12.00),
(19, 14, 1, 1, 12.00, 12.00),
(20, 14, 1, 1, 12.00, 12.00),
(21, 15, 2, 1, 50.99, 50.99),
(22, 15, 2, 1, 50.99, 50.99),
(23, 16, 1, 1, 12.00, 12.00),
(24, 16, 1, 1, 12.00, 12.00),
(25, 17, 1, 1, 12.00, 12.00),
(26, 17, 1, 1, 12.00, 12.00),
(27, 18, 1, 1, 12.00, 12.00),
(28, 18, 1, 1, 12.00, 12.00),
(29, 19, 1, 100, 12.00, 1200.00),
(30, 19, 1, 100, 12.00, 1200.00),
(31, 20, 1, 10, 12.00, 120.00),
(32, 20, 1, 10, 12.00, 120.00),
(33, 21, 1, 11, 12.00, 132.00),
(34, 22, 1, 1, 12.00, 12.00),
(35, 23, 1, 1, 12.00, 12.00),
(36, 24, 1, 1, 12.00, 12.00),
(37, 25, 1, 1, 12.00, 12.00),
(38, 26, 1, 1, 12.00, 12.00),
(39, 27, 1, 2, 12.00, 24.00),
(40, 28, 1, 1, 12.00, 12.00),
(41, 29, 1, 12, 12.00, 144.00),
(42, 30, 1, 1, 12.00, 12.00);

-- --------------------------------------------------------

--
-- Structure de la table `sales`
--

CREATE TABLE `sales` (
  `id` int(11) NOT NULL,
  `sale_date` date NOT NULL,
  `warehouse_id` int(11) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `created_by` int(11) NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `source_credit_sale_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sales`
--

INSERT INTO `sales` (`id`, `sale_date`, `warehouse_id`, `total_amount`, `created_by`, `customer_name`, `source_credit_sale_id`) VALUES
(3, '2025-08-09', 1, 18.00, 35, 'sa', NULL),
(4, '2025-08-13', 1, 18.00, 43, 'ahmed', NULL),
(5, '2025-08-13', 1, 220.00, 43, 'hasennn', NULL),
(6, '2025-08-13', 1, 220.00, 43, 'qsqs', NULL),
(7, '2025-08-13', 1, 220.00, 43, 'bnbn', NULL),
(8, '2025-08-13', 1, 220.00, 43, 'mourad', NULL),
(9, '2025-08-13', 2, 180.00, 43, 'aaaaa', NULL),
(10, '2025-08-13', 2, 54.00, 35, 'semah', NULL),
(11, '2025-08-13', 1, 20.00, 35, 'semah', NULL),
(12, '2025-08-13', 1, 180.00, 35, 'basem', NULL),
(13, '2025-08-13', 1, 180.00, 35, 'basem', NULL),
(14, '2025-08-13', 1, 180.00, 35, 'maram', NULL),
(15, '2025-08-13', 1, 180.00, 35, 'maram', NULL),
(16, '2025-08-13', 1, 180.00, 35, 'maram', NULL),
(17, '2025-08-13', 1, 180.00, 35, 'chaabi', NULL),
(18, '2025-08-13', 1, 100.00, 35, 'anwar', NULL),
(19, '2025-08-13', 1, 440.00, 35, 'Test Customer', NULL),
(20, '2025-08-13', 2, 180.00, 35, 'maram', NULL),
(21, '2025-08-13', 2, 180.00, 35, 'anwar', NULL),
(22, '2025-08-13', 1, 220.00, 35, 'chaabi', NULL),
(23, '2025-08-13', 1, 180.00, 35, 'riadh', NULL),
(24, '2025-08-13', 1, 180.00, 35, 'riadh', NULL),
(25, '2025-08-13', 1, 180.00, 35, 'riadh', NULL),
(26, '2025-08-13', 1, 10.00, 35, 'semah', NULL),
(27, '2025-08-13', 2, 180.00, 35, 'basem', NULL),
(28, '2025-08-21', 1, 440.00, 43, 'nadhem', NULL),
(29, '2025-08-22', 1, 440.00, 43, 'nadhem', NULL),
(30, '2025-08-22', 1, 100.00, 43, 'semah', NULL),
(31, '2025-08-22', 1, 100.00, 43, 'anwar', NULL),
(32, '2025-08-22', 1, 180.00, 43, 'riadh', NULL),
(33, '2025-08-22', 2, 54.00, 43, 'nadhem', NULL),
(34, '2025-08-22', 2, 54.00, 43, 'nadhem', NULL),
(35, '2025-08-25', 1, 440.00, 43, 'Test Customer', NULL),
(36, '2025-08-25', 1, 18.00, 43, 'salah', NULL),
(37, '2025-08-25', 1, 10.00, 43, 'anwar', NULL),
(38, '2025-08-27', 1, 20.00, 43, 'chaabi', NULL),
(39, '2025-08-22', 2, 36.00, 43, 'semah', NULL),
(40, '2025-08-27', 1, 18.00, 43, 'basem', NULL),
(41, '2025-08-27', 1, 18.00, 43, 'basem', NULL),
(42, '2025-08-27', 1, 10.00, 43, 'maram', NULL),
(43, '2025-08-27', 1, 100.00, 43, 'maram', NULL),
(44, '2025-08-27', 1, 100.00, 43, 'basem', 585),
(45, '2025-08-27', 1, 180.00, 1003, 'mariem', NULL),
(46, '2025-08-27', 1, 360.00, 1000, 'mariem', 586),
(47, '2025-09-04', 1, 18.00, 1000, 'basem', 589),
(48, '2025-09-08', 1, 36.00, 1000, 'basem', NULL),
(49, '2025-09-08', 1, 18.00, 1000, 'maram', NULL),
(50, '2025-09-08', 1, 36.00, 1000, 'nadhem', 590),
(51, '2025-09-08', 1, 18.00, 1000, 'chaabi', NULL),
(52, '2025-09-08', 1, 220.00, 1000, 'chaabi', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `sale_items`
--

CREATE TABLE `sale_items` (
  `id` int(11) NOT NULL,
  `sale_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sale_items`
--

INSERT INTO `sale_items` (`id`, `sale_id`, `product_id`, `quantity`, `unit_price`) VALUES
(3, 3, 1, 1, 18.00),
(4, 4, 1, 1, 18.00),
(5, 5, 4, 1, 220.00),
(6, 6, 4, 1, 220.00),
(7, 7, 4, 1, 220.00),
(8, 8, 4, 1, 220.00),
(9, 9, 1, 10, 18.00),
(10, 10, 1, 3, 18.00),
(11, 11, 2, 2, 10.00),
(12, 12, 1, 10, 18.00),
(13, 13, 1, 10, 18.00),
(14, 14, 1, 10, 18.00),
(15, 15, 1, 10, 18.00),
(16, 16, 1, 10, 18.00),
(17, 17, 1, 10, 18.00),
(18, 18, 2, 10, 10.00),
(19, 19, 4, 2, 220.00),
(20, 20, 1, 10, 18.00),
(21, 21, 1, 10, 18.00),
(22, 22, 4, 1, 220.00),
(23, 26, 2, 1, 10.00),
(24, 27, 1, 10, 18.00),
(25, 28, 4, 2, 220.00),
(26, 29, 4, 2, 220.00),
(27, 30, 2, 10, 10.00),
(28, 31, 2, 10, 10.00),
(29, 32, 1, 10, 18.00),
(30, 35, 4, 2, 220.00),
(31, 36, 1, 1, 18.00),
(32, 37, 2, 1, 10.00),
(33, 38, 2, 2, 10.00),
(34, 39, 1, 2, 18.00),
(35, 42, 2, 1, 10.00),
(36, 43, 2, 10, 10.00),
(37, 44, 2, 10, 10.00),
(38, 45, 1, 10, 18.00),
(39, 46, 1, 20, 18.00),
(40, 47, 1, 1, 18.00),
(41, 48, 1, 2, 18.00),
(42, 49, 1, 1, 18.00),
(43, 50, 1, 2, 18.00),
(44, 51, 1, 1, 18.00),
(45, 52, 4, 1, 220.00);

-- --------------------------------------------------------

--
-- Structure de la table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `from_warehouse_id` int(11) DEFAULT NULL,
  `to_warehouse_id` int(11) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `movement_type` enum('transfer','purchase','adjustment') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `user_id` int(11) NOT NULL,
  `note` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `stock_movements`
--

INSERT INTO `stock_movements` (`id`, `product_id`, `from_warehouse_id`, `to_warehouse_id`, `quantity`, `movement_type`, `created_at`, `user_id`, `note`) VALUES
(26, 1, NULL, 1, 100, 'purchase', '2025-08-01 18:47:53', 40, 'Purchase delivery - Purchase ID: 37'),
(27, 1, 1, NULL, 1, '', '2025-08-09 16:21:30', 35, NULL),
(36, 4, NULL, 1, 10, 'purchase', '2025-08-13 14:01:32', 43, 'Stock added from purchase delivery - Purchase ID: 45'),
(40, 4, 1, NULL, 1, '', '2025-08-13 14:11:17', 43, NULL),
(41, 1, NULL, 2, 100, 'purchase', '2025-08-13 14:35:50', 43, 'Stock added from purchase delivery - Purchase ID: 46'),
(42, 1, 2, NULL, 10, '', '2025-08-13 14:36:29', 43, NULL),
(43, 1, 2, NULL, 3, '', '2025-08-13 15:51:08', 35, NULL),
(44, 2, 1, NULL, 2, '', '2025-08-13 15:55:40', 35, NULL),
(45, 1, 1, NULL, 10, '', '2025-08-13 17:11:51', 35, NULL),
(46, 1, 1, NULL, 10, '', '2025-08-13 17:11:51', 35, NULL),
(47, 1, 1, NULL, 10, '', '2025-08-13 17:14:25', 35, NULL),
(48, 1, 1, NULL, 10, '', '2025-08-13 17:14:31', 35, NULL),
(49, 1, 1, NULL, 10, '', '2025-08-13 17:14:31', 35, NULL),
(50, 1, 1, NULL, 10, '', '2025-08-13 17:23:54', 35, NULL),
(51, 2, 1, NULL, 10, '', '2025-08-13 17:27:58', 35, NULL),
(52, 4, 1, NULL, 2, '', '2025-08-13 17:29:44', 35, NULL),
(53, 1, 2, NULL, 10, '', '2025-08-13 17:39:45', 35, NULL),
(54, 1, 2, NULL, 10, '', '2025-08-13 17:41:43', 35, NULL),
(55, 4, 1, NULL, 1, '', '2025-08-13 17:44:06', 35, NULL),
(56, 2, 1, NULL, 1, '', '2025-08-13 17:47:00', 35, NULL),
(57, 1, 2, NULL, 10, '', '2025-08-13 17:47:41', 35, NULL),
(58, 4, NULL, 2, 100, 'purchase', '2025-08-13 17:49:25', 43, 'Stock added from purchase delivery - Purchase ID: 47'),
(59, 1, NULL, 1, 19, 'purchase', '2025-08-13 17:55:37', 1001, 'Stock added from purchase delivery - Purchase ID: 41'),
(60, 1, NULL, 1, 10, 'purchase', '2025-08-13 17:55:49', 1001, 'Stock added from purchase delivery - Purchase ID: 42'),
(61, 2, NULL, 1, 20, 'purchase', '2025-08-13 17:55:52', 1001, 'Stock added from purchase delivery - Purchase ID: 43'),
(62, 4, NULL, 1, 2, 'purchase', '2025-08-13 17:55:55', 1001, 'Stock added from purchase delivery - Purchase ID: 44'),
(63, 2, NULL, 2, 100, 'purchase', '2025-08-13 18:06:58', 1001, 'Stock added from purchase delivery - Purchase ID: 48'),
(64, 4, 1, NULL, 2, '', '2025-08-21 11:48:09', 43, NULL),
(65, 4, 1, NULL, 2, '', '2025-08-22 15:00:05', 43, NULL),
(66, 2, 1, NULL, 10, '', '2025-08-22 16:39:32', 43, NULL),
(67, 2, 1, NULL, 10, '', '2025-08-22 16:39:52', 43, NULL),
(68, 1, 1, NULL, 10, '', '2025-08-22 16:41:09', 43, NULL),
(69, 4, 1, NULL, 2, '', '2025-08-25 15:03:30', 43, NULL),
(70, 1, 1, NULL, 1, '', '2025-08-25 15:09:10', 43, NULL),
(71, 2, 1, NULL, 1, '', '2025-08-25 16:55:57', 43, NULL),
(72, 2, 1, NULL, 2, '', '2025-08-27 14:39:44', 43, NULL),
(73, 1, 2, NULL, 2, '', '2025-08-27 14:41:14', 43, NULL),
(74, 2, 1, NULL, 1, '', '2025-08-27 14:44:45', 43, NULL),
(75, 2, 1, NULL, 10, '', '2025-08-27 15:06:20', 43, NULL),
(76, 2, 1, NULL, 10, '', '2025-08-27 15:19:41', 43, NULL),
(77, 1, NULL, 1, 100, 'purchase', '2025-08-27 15:43:14', 1001, 'Stock added from purchase delivery - Purchase ID: 49'),
(78, 1, 1, NULL, 10, '', '2025-08-27 15:44:24', 1003, NULL),
(79, 1, 1, NULL, 20, '', '2025-08-27 15:46:51', 1000, NULL),
(80, 1, 1, NULL, 1, 'adjustment', '2025-09-03 16:47:26', 43, 'Vente à crédit - Client ID: 1009 (Vente #588)'),
(81, 2, NULL, 1, 100, 'purchase', '2025-09-04 01:25:12', 1001, 'Achat livré: Produit: Roulement 6202 - Quantité: 100 - Prix: 6.00'),
(82, 4, NULL, 2, 1, 'purchase', '2025-09-04 01:25:12', 1001, 'Achat livré: Produit: Vérin hydraulique - Quantité: 1 - Prix: 150.00'),
(83, 1, NULL, 1, 1, 'purchase', '2025-09-04 01:25:12', 1001, 'Achat livré: Produit: Filtre à huile - Quantité: 1 - Prix: 12.00'),
(84, 1, 1, NULL, 1, 'transfer', '2025-09-04 11:33:48', 1000, 'Vente: basem - Produit: Filtre à huile - Quantité: 1 - Prix: 18.00'),
(85, 1, 1, NULL, 2, 'transfer', '2025-09-08 16:59:00', 1000, 'Vente: basem - Produit: Filtre à huile - Quantité: 2 - Prix: 18'),
(86, 1, 1, NULL, 1, 'transfer', '2025-09-08 17:00:59', 1000, 'Vente: maram - Produit: Filtre à huile - Quantité: 1 - Prix: 18'),
(87, 1, 1, NULL, 1, 'transfer', '2025-09-08 17:32:11', 1000, 'Vente: chaabi - Produit: Filtre à huile - Quantité: 1 - Prix: 18'),
(88, 1, 1, 2, 10, 'transfer', '2025-09-08 17:54:08', 1000, 'Transfer from warehouse 1 to warehouse 2'),
(89, 4, 2, 1, 20, 'transfer', '2025-09-08 18:00:49', 1000, 'Transfer from warehouse 2 to warehouse 1'),
(90, 1, 1, 2, 4, 'transfer', '2025-09-08 18:01:49', 1000, 'Transfer from warehouse 1 to warehouse 2'),
(91, 4, 2, 1, 1, 'transfer', '2025-09-08 18:05:48', 1000, 'Transfer from warehouse 2 to warehouse 1');

-- --------------------------------------------------------

--
-- Structure de la table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL,
  `contact_info` text DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `suppliers`
--

INSERT INTO `suppliers` (`id`, `contact_info`, `address`, `name`) VALUES
(1, 'contact@abcspareparts.com, 123-456-7890', '123 Main Street, City', 'ABC Spare Parts'),
(2, 'wanes@gmail.com', 'tunis', 'wanesauto');

-- --------------------------------------------------------

--
-- Structure de la table `supplier_credits`
--

CREATE TABLE `supplier_credits` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `credit_amount` decimal(10,2) NOT NULL,
  `remaining_amount` decimal(10,2) NOT NULL,
  `source_type` enum('purchase_return','manual_adjustment') NOT NULL,
  `source_id` int(11) DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `status` enum('active','expired','used') DEFAULT 'active',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `supplier_credits`
--

INSERT INTO `supplier_credits` (`id`, `supplier_id`, `credit_amount`, `remaining_amount`, `source_type`, `source_id`, `expiry_date`, `status`, `notes`, `created_at`, `updated_at`) VALUES
(3, 1, 60.00, 0.00, 'purchase_return', 8, NULL, 'used', 'Credit from purchase return #8', '2025-08-14 17:57:27', '2025-08-14 17:58:00'),
(4, 1, 0.00, 0.00, 'manual_adjustment', NULL, '2026-08-14', 'active', 'Test credit for debugging', '2025-08-14 18:46:18', '2025-08-14 18:46:18'),
(5, 1, 0.00, 0.00, 'manual_adjustment', NULL, '2026-08-14', 'active', 'Test credit for debugging', '2025-08-14 18:46:31', '2025-08-14 18:46:31'),
(6, 1, 60.00, 60.00, 'manual_adjustment', NULL, '2026-08-14', 'active', 'Test credit for debugging', '2025-08-14 18:48:06', '2025-08-14 18:48:48'),
(7, 1, 600.00, 600.00, 'purchase_return', 10, NULL, 'active', 'Credit from purchase return #10', '2025-08-14 19:00:50', '2025-08-14 19:00:50'),
(8, 1, 300.00, 300.00, 'purchase_return', 9, NULL, 'active', 'Credit from purchase return #9', '2025-08-14 19:00:53', '2025-08-14 19:00:53'),
(9, 1, 1200.00, 1200.00, 'purchase_return', 19, NULL, 'active', 'Credit from purchase return #19', '2025-08-19 14:25:49', '2025-08-19 14:25:49'),
(10, 1, 12.00, 12.00, 'purchase_return', 22, NULL, 'active', 'Credit from purchase return #22', '2025-08-26 16:24:29', '2025-08-26 16:24:29'),
(11, 1, 144.00, 144.00, 'purchase_return', 29, NULL, 'active', 'Credit from purchase return #29', '2025-08-26 17:24:50', '2025-08-26 17:24:50'),
(12, 1, 12.00, 12.00, 'purchase_return', 30, NULL, 'active', 'Credit from purchase return #30', '2025-08-26 17:33:56', '2025-08-26 17:33:56');

-- --------------------------------------------------------

--
-- Structure de la table `supplier_credit_usage`
--

CREATE TABLE `supplier_credit_usage` (
  `id` int(11) NOT NULL,
  `supplier_credit_id` int(11) NOT NULL,
  `purchase_id` int(11) NOT NULL,
  `amount_used` decimal(10,2) NOT NULL,
  `used_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `supplier_credit_usage`
--

INSERT INTO `supplier_credit_usage` (`id`, `supplier_credit_id`, `purchase_id`, `amount_used`, `used_at`) VALUES
(1, 3, 30, 60.00, '2025-08-14 17:58:00');

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','manager','cashier') NOT NULL DEFAULT 'cashier',
  `warehouse_id` int(11) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone_number` int(11) NOT NULL,
  `createdAt` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `updatedAt` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `password_hash`, `role`, `warehouse_id`, `name`, `email`, `phone_number`, `createdAt`, `updatedAt`) VALUES
(1, 'hashed_password_here', 'cashier', NULL, 'Admin User', 'admin@example.com', 0, '2025-08-09 19:20:55.873852', '2025-08-09 19:20:55.873852'),
(13, '$2b$10$C/9/Uv5C45s0oNIckl7kg.Wr2IYuxtx/QU1kmqF2zAS6/wVNeQwUS', 'admin', 1, 'Waness Admin', 'waness.admin@example.com', 987654321, '2025-06-22 00:23:48.419410', '2025-06-22 00:23:48.426064'),
(35, '$2b$10$13Jpn9.wjqDWLJkrw..vO.1AYLSGFFf1LL1hZ23iJ7NYXPhRfyaVe', 'cashier', 3, 'aziz', 'azizabidilol7@gmail.com', 93088283, '2025-07-07 15:42:45.877317', '2025-07-13 21:11:30.528903'),
(36, '$2b$10$OAPktO29QaHyE4wDDkz2I.DGCo0NxsHibG7apmkglJucl.UXL9hYC', 'cashier', 4, 'maram', 'njahimaram2@gmail.com', 125698745, '2025-07-13 14:04:55.840635', '2025-07-17 23:37:38.000000'),
(40, '$2b$10$Y95xUTot5X08A6hz2fQVDetd1akqFDOpYs8pZOz1o0FFsczJ2k8ES', 'manager', 1, 'aziz', 'zizouaziz5992559292552@gmail.com', 93088285, '2025-07-29 01:49:21.003862', '2025-07-29 01:50:31.042010'),
(43, '$2b$10$/AAX9o47HtlYUpMRqdUyQ.7Of4NtMWaID4Q3oyouGjdMgL9c6smhu', 'admin', NULL, 'wanes', '7asen123456789azerazerazer@gmail.com', 93088281, '2025-08-06 06:34:28.699859', '2025-08-13 19:49:59.471007'),
(100, 'hashed_password_here', 'cashier', NULL, 'Admin User', 'admina1@example.com', 1234567890, '2025-08-09 19:22:45.746871', '2025-08-09 19:22:45.746871'),
(110, 'hashed_password_here', 'cashier', NULL, 'Admin User', 'admina1a@example.com', 1234567770, '2025-08-09 19:23:56.943841', '2025-08-09 19:23:56.943841'),
(111, '7895466666', 'cashier', NULL, 'Admin User', 'admina771@example.com', 189657458, '2025-08-09 19:26:51.281035', '2025-08-09 19:26:51.281035'),
(114, '7895466666', 'cashier', NULL, 'Admin User', 'admina77781@example.com', 1896577458, '2025-08-09 19:27:25.371096', '2025-08-09 19:27:25.371096'),
(117, 'hashed_password_here', 'admin', NULL, 'Admin User', 'admina1eee@example.com', 2147483647, '2025-08-09 19:28:38.207628', '2025-08-09 19:28:38.207628'),
(999, 'hashed_password_here', 'admin', NULL, 'Admin Test', 'admin_test_', 123456789, '2025-08-09 19:42:51.376211', '2025-08-09 19:42:51.376211'),
(1000, '$2b$10$JdlVidTVYzMLqVy/Jchwnuu3gU89k28iRlToCNNe4XESOv4QgIIt.', 'admin', NULL, 'aziz', 'aziz@admin.com', 54788954, '2025-08-13 19:50:57.699500', '2025-08-13 19:50:57.699500'),
(1001, '$2b$10$wqzQzRjlJLt6KHgUJENs/e/EzMabNeKfBhYMP160BiBaTWnFPV0ZC', 'manager', NULL, 'aziz', 'aziz@manager.com', 78456123, '2025-08-13 19:52:14.542566', '2025-08-13 19:52:14.542566'),
(1002, '$2b$10$3Tzf3sM/6WwTGx4QRC6qCuCqUhlwskJnBRZuyoNX5NDGcE97YLPRq', 'cashier', NULL, 'aziz', 'aziz@cashier.com', 45879321, '2025-08-13 19:53:48.412078', '2025-08-13 19:53:48.412078'),
(1003, '$2b$10$TVzj7uAqP8sRtoJZk2SRAuRyrjFJduA.Dhav3prtuHRjReKRPb3Aa', 'cashier', NULL, 'mariem', 'mariem@gmail.com', 45456123, '2025-08-27 16:40:54.467881', '2025-08-27 16:40:54.467881'),
(1004, '$2b$10$aLajvT.Ee7U6vbsq51v2seiZK3hGW9CelqjSW94uFETc13ZyGhJXq', 'cashier', NULL, 'skander', 'skander@gmail.com', 45123456, '2025-09-04 13:17:05.647660', '2025-09-04 13:17:05.647660');

-- --------------------------------------------------------

--
-- Structure de la table `warehouses`
--

CREATE TABLE `warehouses` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `location` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `warehouses`
--

INSERT INTO `warehouses` (`id`, `name`, `location`) VALUES
(1, 'wannes_auto_depo1', 'mnihla'),
(2, 'wannes_auto_depo2', 'ebn_khouldoun'),
(3, 'Central Warehouse', '123 Main Street, City'),
(4, 'ee', 'ee'),
(5, 'Main Warehouse', 'Downtown'),
(999, 'Test Warehouse', 'Test Location'),
(1000, 'ILYES', 'BIZERTE');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `credit_payments`
--
ALTER TABLE `credit_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `received_by` (`received_by`),
  ADD KEY `idx_credit_payments_credit_sale` (`credit_sale_id`),
  ADD KEY `idx_credit_payments_date` (`payment_date`),
  ADD KEY `idx_cp_credit_sale_id` (`credit_sale_id`);

--
-- Index pour la table `credit_sales`
--
ALTER TABLE `credit_sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `warehouse_id` (`warehouse_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_credit_sales_customer` (`customer_id`),
  ADD KEY `idx_credit_sales_status` (`status`);

--
-- Index pour la table `credit_sale_items`
--
ALTER TABLE `credit_sale_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `credit_sale_id` (`credit_sale_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `idx_csi_credit_sale_id` (`credit_sale_id`);

--
-- Index pour la table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Index pour la table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `operational_expenses`
--
ALTER TABLE `operational_expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_operational_expenses_warehouse` (`warehouse_id`),
  ADD KEY `fk_operational_expenses_user` (`created_by`);

--
-- Index pour la table `otp`
--
ALTER TABLE `otp`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_db724db1bc3d94ad5ba38518433` (`userId`);

--
-- Index pour la table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `IDX_7adc941e5c6824073df37db040` (`reference_code`);

--
-- Index pour la table `product_stocks`
--
ALTER TABLE `product_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_1e17816fecdb81490a1c2ae3682` (`product_id`),
  ADD KEY `FK_ea475d7f52bdec77adddeed693b` (`warehouse_id`);

--
-- Index pour la table `product_transfers`
--
ALTER TABLE `product_transfers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `approved_by` (`approved_by`),
  ADD KEY `processed_by` (`processed_by`),
  ADD KEY `idx_product_transfers_product` (`product_id`),
  ADD KEY `idx_product_transfers_from_warehouse` (`from_warehouse_id`),
  ADD KEY `idx_product_transfers_to_warehouse` (`to_warehouse_id`),
  ADD KEY `idx_product_transfers_status` (`status`),
  ADD KEY `idx_product_transfers_priority` (`priority`),
  ADD KEY `idx_product_transfers_requested_by` (`requested_by`),
  ADD KEY `idx_product_transfers_created_at` (`created_at`);

--
-- Index pour la table `purchases`
--
ALTER TABLE `purchases`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_d5fec047f705d5b510c19379b95` (`supplier_id`),
  ADD KEY `FK_70ebb313de49b0256d21b1527d4` (`created_by`);

--
-- Index pour la table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_607211d59b13e705a673a999ab5` (`purchase_id`),
  ADD KEY `FK_43694b2fa800ce38d2da9ce74d6` (`product_id`),
  ADD KEY `FK_3f40f087a781526ad91a94d4078` (`warehouse_id`);

--
-- Index pour la table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sales_source_credit_sale` (`source_credit_sale_id`),
  ADD KEY `FK_45e72974e37a5c6b1ae756d567d` (`warehouse_id`),
  ADD KEY `FK_83a12e5e2723eafe9a47c441457` (`created_by`);

--
-- Index pour la table `sale_items`
--
ALTER TABLE `sale_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_c210a330b80232c29c2ad68462a` (`sale_id`),
  ADD KEY `FK_4ecae62db3f9e9cc9a368d57adb` (`product_id`);

--
-- Index pour la table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_2c1bb05b80ddcc562cd28d826c6` (`product_id`),
  ADD KEY `FK_d7fedfd6ee0f4a06648c48631c6` (`user_id`),
  ADD KEY `FK_4cb920f745c259c897f883a3042` (`from_warehouse_id`),
  ADD KEY `FK_c819677e66143db1ad0075a82d9` (`to_warehouse_id`);

--
-- Index pour la table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `supplier_credits`
--
ALTER TABLE `supplier_credits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Index pour la table `supplier_credit_usage`
--
ALTER TABLE `supplier_credit_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `supplier_credit_id` (`supplier_credit_id`),
  ADD KEY `purchase_id` (`purchase_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `IDX_97672ac88f789774dd47f7c8be` (`email`),
  ADD UNIQUE KEY `IDX_17d1817f241f10a3dbafb169fd` (`phone_number`),
  ADD KEY `FK_fa43267f9de1621105d7f0fea48` (`warehouse_id`);

--
-- Index pour la table `warehouses`
--
ALTER TABLE `warehouses`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `credit_payments`
--
ALTER TABLE `credit_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT pour la table `credit_sales`
--
ALTER TABLE `credit_sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=591;

--
-- AUTO_INCREMENT pour la table `credit_sale_items`
--
ALTER TABLE `credit_sale_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=88;

--
-- AUTO_INCREMENT pour la table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1014;

--
-- AUTO_INCREMENT pour la table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `operational_expenses`
--
ALTER TABLE `operational_expenses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT pour la table `otp`
--
ALTER TABLE `otp`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT pour la table `product_stocks`
--
ALTER TABLE `product_stocks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT pour la table `product_transfers`
--
ALTER TABLE `product_transfers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `purchases`
--
ALTER TABLE `purchases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT pour la table `purchase_items`
--
ALTER TABLE `purchase_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT pour la table `sales`
--
ALTER TABLE `sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT pour la table `sale_items`
--
ALTER TABLE `sale_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT pour la table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=92;

--
-- AUTO_INCREMENT pour la table `suppliers`
--
ALTER TABLE `suppliers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `supplier_credits`
--
ALTER TABLE `supplier_credits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT pour la table `supplier_credit_usage`
--
ALTER TABLE `supplier_credit_usage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1005;

--
-- AUTO_INCREMENT pour la table `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1001;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `credit_payments`
--
ALTER TABLE `credit_payments`
  ADD CONSTRAINT `credit_payments_ibfk_2` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_cp_cs_id_cascade_20250821_01` FOREIGN KEY (`credit_sale_id`) REFERENCES `credit_sales` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_credit_payments_credit_sale_id` FOREIGN KEY (`credit_sale_id`) REFERENCES `credit_sales` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `credit_sales`
--
ALTER TABLE `credit_sales`
  ADD CONSTRAINT `credit_sales_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  ADD CONSTRAINT `credit_sales_ibfk_2` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `credit_sales_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `credit_sale_items`
--
ALTER TABLE `credit_sale_items`
  ADD CONSTRAINT `credit_sale_items_ibfk_1` FOREIGN KEY (`credit_sale_id`) REFERENCES `credit_sales` (`id`),
  ADD CONSTRAINT `credit_sale_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `fk_csi_cs_id_cascade_20250821_01` FOREIGN KEY (`credit_sale_id`) REFERENCES `credit_sales` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `operational_expenses`
--
ALTER TABLE `operational_expenses`
  ADD CONSTRAINT `fk_operational_expenses_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_operational_expenses_warehouse` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Contraintes pour la table `otp`
--
ALTER TABLE `otp`
  ADD CONSTRAINT `FK_db724db1bc3d94ad5ba38518433` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Contraintes pour la table `product_stocks`
--
ALTER TABLE `product_stocks`
  ADD CONSTRAINT `FK_1e17816fecdb81490a1c2ae3682` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_ea475d7f52bdec77adddeed693b` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Contraintes pour la table `product_transfers`
--
ALTER TABLE `product_transfers`
  ADD CONSTRAINT `product_transfers_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `product_transfers_ibfk_2` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `product_transfers_ibfk_3` FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`),
  ADD CONSTRAINT `product_transfers_ibfk_4` FOREIGN KEY (`requested_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `product_transfers_ibfk_5` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `product_transfers_ibfk_6` FOREIGN KEY (`processed_by`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `purchases`
--
ALTER TABLE `purchases`
  ADD CONSTRAINT `FK_70ebb313de49b0256d21b1527d4` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_d5fec047f705d5b510c19379b95` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Contraintes pour la table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD CONSTRAINT `FK_3f40f087a781526ad91a94d4078` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_43694b2fa800ce38d2da9ce74d6` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_607211d59b13e705a673a999ab5` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Contraintes pour la table `sales`
--
ALTER TABLE `sales`
  ADD CONSTRAINT `FK_45e72974e37a5c6b1ae756d567d` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_83a12e5e2723eafe9a47c441457` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_sales_source_credit` FOREIGN KEY (`source_credit_sale_id`) REFERENCES `credit_sales` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `sale_items`
--
ALTER TABLE `sale_items`
  ADD CONSTRAINT `FK_4ecae62db3f9e9cc9a368d57adb` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_c210a330b80232c29c2ad68462a` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Contraintes pour la table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `FK_2c1bb05b80ddcc562cd28d826c6` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_4cb920f745c259c897f883a3042` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_c819677e66143db1ad0075a82d9` FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_d7fedfd6ee0f4a06648c48631c6` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Contraintes pour la table `supplier_credits`
--
ALTER TABLE `supplier_credits`
  ADD CONSTRAINT `supplier_credits_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`);

--
-- Contraintes pour la table `supplier_credit_usage`
--
ALTER TABLE `supplier_credit_usage`
  ADD CONSTRAINT `supplier_credit_usage_ibfk_1` FOREIGN KEY (`supplier_credit_id`) REFERENCES `supplier_credits` (`id`),
  ADD CONSTRAINT `supplier_credit_usage_ibfk_2` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`);

--
-- Contraintes pour la table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `FK_fa43267f9de1621105d7f0fea48` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
