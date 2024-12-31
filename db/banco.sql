CREATE DATABASE  IF NOT EXISTS `cardapio_dinamico` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cardapio_dinamico`;
-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: localhost    Database: cardapio_dinamico
-- ------------------------------------------------------
-- Server version	8.3.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `carrinho`
--

DROP TABLE IF EXISTS `carrinho`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `carrinho` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `produto_id` int NOT NULL,
  `quantidade` int NOT NULL DEFAULT '1',
  `data_adicao` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `produto_id` (`produto_id`)
) ENGINE=MyISAM AUTO_INCREMENT=447 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `carrinho`
--

LOCK TABLES `carrinho` WRITE;
/*!40000 ALTER TABLE `carrinho` DISABLE KEYS */;
INSERT INTO `carrinho` VALUES (343,5,21,1,'2024-11-29 18:44:40'),(344,5,22,1,'2024-11-29 18:45:11'),(446,4,60,4,'2024-12-26 15:27:51');
/*!40000 ALTER TABLE `carrinho` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `before_carrinho_insert` BEFORE INSERT ON `carrinho` FOR EACH ROW BEGIN
    DECLARE estoque_disponivel INT;
    DECLARE quantidade_total INT;

    -- Obter o estoque disponível do produto
    SELECT estoque INTO estoque_disponivel
    FROM produtos
    WHERE id = NEW.produto_id;

    -- Calcular o total acumulado no carrinho do mesmo produto
    SELECT IFNULL(SUM(quantidade), 0) INTO quantidade_total
    FROM carrinho
    WHERE produto_id = NEW.produto_id;

    -- Verificar se o estoque disponível é suficiente
    IF (quantidade_total + NEW.quantidade) > estoque_disponivel THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estoque insuficiente para o produto selecionado.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_carrinho_insert` AFTER INSERT ON `carrinho` FOR EACH ROW BEGIN
    -- Atualizar o estoque do produto
    UPDATE produtos
    SET estoque = estoque - NEW.quantidade
    WHERE id = NEW.produto_id;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_carrinho_update` AFTER UPDATE ON `carrinho` FOR EACH ROW BEGIN
    DECLARE diferenca INT;

    -- Calcula a diferença na quantidade
    SET diferenca = NEW.quantidade - OLD.quantidade;

    IF diferenca > 0 THEN
        -- Reduz o estoque do produto
        UPDATE produtos
        SET estoque = estoque - diferenca
        WHERE id = NEW.produto_id AND estoque >= diferenca;

        -- Verifica se a atualização foi bem-sucedida
        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para atualizar a quantidade no carrinho.';
        END IF;
    ELSEIF diferenca < 0 THEN
        -- Restaura o estoque do produto
        UPDATE produtos
        SET estoque = estoque + ABS(diferenca)
        WHERE id = NEW.produto_id;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `remover_estoque_carrinho` AFTER DELETE ON `carrinho` FOR EACH ROW BEGIN
    -- Repor a quantidade removida do carrinho no estoque
    UPDATE produtos
    SET estoque = estoque + OLD.quantidade
    WHERE id = OLD.produto_id;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `enderecos_entrega`
--

DROP TABLE IF EXISTS `enderecos_entrega`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enderecos_entrega` (
  `id` int NOT NULL AUTO_INCREMENT,
  `rua` varchar(255) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `complemento` varchar(100) DEFAULT NULL,
  `bairro` varchar(100) NOT NULL,
  `cidade` varchar(100) NOT NULL,
  `estado` varchar(2) NOT NULL,
  `pais` varchar(3) NOT NULL DEFAULT 'BRA',
  `cep` varchar(9) NOT NULL,
  `usuario_id` int NOT NULL,
  `data_criacao` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enderecos_entrega`
--

LOCK TABLES `enderecos_entrega` WRITE;
/*!40000 ALTER TABLE `enderecos_entrega` DISABLE KEYS */;
INSERT INTO `enderecos_entrega` VALUES (1,'neymar','1384','q52 l7','Senador Canedo','Goias','GO','BRA','75258831',1,'2024-09-20 13:23:55'),(2,'Anhanguera','775','quadra 215, lote 9','Novo Mundo','Goiânia','Go','BRA','74705010',3,'2024-09-21 04:05:57'),(3,'Av.anhanguera','775',' Quadra 215, Lote 9','novo mundo','Goiânia','GO','BRA','74705010',4,'2024-09-23 12:43:56');
/*!40000 ALTER TABLE `enderecos_entrega` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `itens_venda`
--

DROP TABLE IF EXISTS `itens_venda`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `itens_venda` (
  `id` int NOT NULL AUTO_INCREMENT,
  `venda_id` int NOT NULL,
  `produto_id` int NOT NULL,
  `quantidade` int NOT NULL,
  `preco` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `venda_id` (`venda_id`),
  KEY `produto_id` (`produto_id`)
) ENGINE=MyISAM AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `itens_venda`
--

LOCK TABLES `itens_venda` WRITE;
/*!40000 ALTER TABLE `itens_venda` DISABLE KEYS */;
INSERT INTO `itens_venda` VALUES (47,31,22,1,10.00),(48,31,21,2,10.00),(49,32,25,1,10.00),(50,32,22,5,10.00),(51,33,31,1,10.00),(52,33,8,1,5.00),(53,35,40,1,2.00),(54,35,37,1,12.00),(55,36,44,1,88.00),(56,37,48,1,88.00),(57,37,47,1,23.00);
/*!40000 ALTER TABLE `itens_venda` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produtos`
--

DROP TABLE IF EXISTS `produtos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produtos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `descricao` text NOT NULL,
  `preco` decimal(10,2) NOT NULL,
  `estoque` int NOT NULL DEFAULT '0',
  `categoria` enum('entradas','principais','bebidas','sobremesas') NOT NULL,
  `imagem` varchar(255) DEFAULT NULL,
  `data_criacao` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produtos`
--

LOCK TABLES `produtos` WRITE;
/*!40000 ALTER TABLE `produtos` DISABLE KEYS */;
INSERT INTO `produtos` VALUES (60,'dfgdfd','sd',23.00,19,'entradas','675c6b0a913dc.jpg','2024-12-13 17:12:42');
/*!40000 ALTER TABLE `produtos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transacoes`
--

DROP TABLE IF EXISTS `transacoes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transacoes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reference_id` varchar(50) NOT NULL,
  `cliente_nome` varchar(255) NOT NULL,
  `cliente_email` varchar(191) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `metodo_pagamento` enum('CREDIT_CARD','BOLETO','PIX') NOT NULL,
  `status` enum('Pendente','Pago','Cancelado') DEFAULT 'Pendente',
  `data_criacao` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `numero_cartao` varchar(20) DEFAULT NULL,
  `exp_mes` varchar(2) DEFAULT NULL,
  `exp_ano` varchar(4) DEFAULT NULL,
  `codigo_seguranca` varchar(4) DEFAULT NULL,
  `titular_cartao` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transacoes`
--

LOCK TABLES `transacoes` WRITE;
/*!40000 ALTER TABLE `transacoes` DISABLE KEYS */;
INSERT INTO `transacoes` VALUES (1,'ref-12345','João Silva','joao@example.com',150.50,'CREDIT_CARD','Pendente','2024-09-19 13:27:30','4111111111111111','12','2025','123','João Silva');
/*!40000 ALTER TABLE `transacoes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `email` varchar(191) NOT NULL,
  `cpf` varchar(11) DEFAULT NULL,
  `senha` varchar(255) NOT NULL,
  `telefone` varchar(9) DEFAULT NULL,
  `dd` varchar(2) DEFAULT NULL,
  `endereco` text,
  `foto` varchar(255) DEFAULT NULL,
  `data_cadastro` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'jose teste','jose@gmail.com','12345678909','$2y$10$sn4AaammqQ.hLnlpXNIqtuRaqCn/xWiX0hELtXyzMKo64aWItTGLy','991098685','62','Rua bv23 Q52 l7','D1.jpeg','2024-09-11 18:57:34'),(3,'Pedro','pedro@gmail.com','05974378156','$2y$10$n/p5DQnyD.6jlqpHnWBYM.VHZXZLiIZzQx1x.2bgpU1t2/ZICeN1.','995776100','62',NULL,'P1.png','2024-09-21 04:05:57'),(4,'teste','teste@gmail.com','64335585187','$2y$10$d4gJSUi519OtqoCgpOsGyOxDH86OTODvfBcmlLsSfqWjclAQffdjS','993041755','62',NULL,'P1.png','2024-09-23 12:43:56');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios_adm`
--

DROP TABLE IF EXISTS `usuarios_adm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios_adm` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `email` varchar(191) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `data_criacao` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios_adm`
--

LOCK TABLES `usuarios_adm` WRITE;
/*!40000 ALTER TABLE `usuarios_adm` DISABLE KEYS */;
INSERT INTO `usuarios_adm` VALUES (1,'Administrador','admin@example.com','e7d80ffeefa212b7c5c55700e4f7193e','2024-09-11 22:21:43');
/*!40000 ALTER TABLE `usuarios_adm` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vendas`
--

DROP TABLE IF EXISTS `vendas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `cliente_id` int DEFAULT NULL,
  `data_venda` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `total` decimal(10,2) NOT NULL,
  `status` enum('Pendente','Pago (Cartão De Crédito)','Pago (Pix)','Pago (Dinheiro)') DEFAULT 'Pendente',
  `status_pedido` enum('Pedido Feito','Em Preparo','Saiu para Entrega','Entregue') DEFAULT 'Pedido Feito',
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`)
) ENGINE=MyISAM AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vendas`
--

LOCK TABLES `vendas` WRITE;
/*!40000 ALTER TABLE `vendas` DISABLE KEYS */;
INSERT INTO `vendas` VALUES (31,4,'2024-11-30 16:42:49',30.00,'Pago (Cartão De Crédito)','Pedido Feito'),(32,4,'2024-12-01 02:05:14',60.00,'Pendente','Pedido Feito'),(33,4,'2024-12-01 18:23:57',15.00,'Pendente','Pedido Feito'),(34,4,'2024-12-01 18:38:34',0.00,'Pendente','Pedido Feito'),(35,4,'2024-12-01 19:02:16',14.00,'Pendente','Pedido Feito'),(36,4,'2024-12-01 19:09:03',88.00,'Pendente','Pedido Feito'),(37,4,'2024-12-02 09:52:12',111.00,'Pendente','Pedido Feito');
/*!40000 ALTER TABLE `vendas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'cardapio_dinamico'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-12-31 10:23:22
