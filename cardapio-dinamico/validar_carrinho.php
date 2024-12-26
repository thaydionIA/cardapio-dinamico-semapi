<?php
session_start();
require_once 'db/conexao.php';

$usuario_id = $_SESSION['user_id'] ?? null;

if (!$usuario_id || empty($_SESSION['carrinho'])) {
    echo json_encode(['status' => 'erro', 'mensagem' => 'Carrinho vazio.']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT c.produto_id, c.quantidade, p.nome, p.estoque 
                           FROM carrinho c
                           LEFT JOIN produtos p ON c.produto_id = p.id
                           WHERE c.usuario_id = :usuario_id");
    $stmt->bindParam(':usuario_id', $usuario_id);
    $stmt->execute();
    $carrinho_db = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($carrinho_db as $item) {
        if ($item['estoque'] === null || $item['estoque'] < $item['quantidade']) {
            $stmt_remove = $pdo->prepare("DELETE FROM carrinho WHERE usuario_id = :usuario_id AND produto_id = :produto_id");
            $stmt_remove->bindParam(':usuario_id', $usuario_id);
            $stmt_remove->bindParam(':produto_id', $item['produto_id']);
            $stmt_remove->execute();
            unset($_SESSION['carrinho'][$item['produto_id']]);
        }
    }

    if (empty($_SESSION['carrinho'])) {
        echo json_encode(['status' => 'erro', 'mensagem' => 'Carrinho vazio.']);
        exit;
    }

    echo json_encode(['status' => 'ok']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'erro', 'mensagem' => 'Erro ao validar o carrinho.']);
}
?>
