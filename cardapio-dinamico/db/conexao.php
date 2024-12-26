<?php
$host = 'localhost';
$db = 'u413819793_CardDinm';
$user = 'u413819793_rt';
$pass = '&RfZpu0[E3q';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo 'Erro ao conectar com o MySQL: ' . $e->getMessage();
    exit();
}
?>

