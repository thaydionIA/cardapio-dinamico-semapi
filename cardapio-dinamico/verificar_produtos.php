<?php
session_start();
require_once 'db/conexao.php';

if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'error' => 'Usuário não autenticado.']);
    exit;
}

$usuario_id = $_SESSION['user_id'];
$produtos_faltando = [];

try {
    // Buscar todos os produtos no carrinho do usuário
    $stmt = $pdo->prepare("SELECT produto_id FROM carrinho WHERE usuario_id = :usuario_id");
    $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
    $stmt->execute();
    $produtos_carrinho = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Atualizar a sessão do carrinho antes de verificar produtos
    $_SESSION['carrinho'] = [];
    foreach ($produtos_carrinho as $item) {
        $_SESSION['carrinho'][$item['produto_id']] = 1;
    }

    // Verificar se os produtos do carrinho existem na tabela produtos
    foreach ($produtos_carrinho as $item) {
        $produto_id = $item['produto_id'];

        // Verifica se o produto existe
        $stmt = $pdo->prepare("SELECT id FROM produtos WHERE id = :id");
        $stmt->bindParam(':id', $produto_id, PDO::PARAM_INT);
        $stmt->execute();
        $produto = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$produto) {
            // Produto não encontrado na tabela 'produtos'
            $produtos_faltando[] = $produto_id;

            // Remover do carrinho do banco de dados
            $stmt = $pdo->prepare("DELETE FROM carrinho WHERE usuario_id = :usuario_id AND produto_id = :produto_id");
            $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
            $stmt->bindParam(':produto_id', $produto_id, PDO::PARAM_INT);
            $stmt->execute();
        }
    }

    if (empty($produtos_faltando)) {
        // Todos os produtos existem, pode prosseguir
        echo json_encode(['success' => true]);
    } else {
        // Produtos faltando, retornar erro com a lista dos IDs ausentes
        echo json_encode(['success' => false, 'produtos_faltando' => $produtos_faltando]);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => 'Erro ao verificar produtos: ' . $e->getMessage()]);
}
