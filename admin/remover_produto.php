<?php
session_start();

// Verificar se o usuário está logado
if (!isset($_SESSION['usuario'])) {
    header("Location: login.php");
    exit();
}

require_once '../db/conexao.php';

// Verificar se o ID do produto foi passado
if (isset($_GET['id'])) {
    $id = $_GET['id'];

    try {
        // Iniciar uma transação para garantir consistência
        $pdo->beginTransaction();

        // Buscar a imagem associada ao produto
        $stmt = $pdo->prepare("SELECT imagem FROM produtos WHERE id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
        $produto = $stmt->fetch(PDO::FETCH_ASSOC);

        // Remover a imagem do servidor, se existir
        if ($produto && $produto['imagem']) {
            $imagemPath = 'uploads/produtos/' . $produto['imagem'];
            if (file_exists($imagemPath)) {
                unlink($imagemPath);
            }
        }

        // Remover o produto do carrinho
        $stmt = $pdo->prepare("DELETE FROM carrinho WHERE produto_id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        // Remover o produto da tabela de produtos
        $stmt = $pdo->prepare("DELETE FROM produtos WHERE id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        // Confirmar a transação
        $pdo->commit();

        // Redirecionar para a página de gerenciamento de produtos
        header("Location: gerenciar_produtos.php");
        exit();
    } catch (Exception $e) {
        // Reverter a transação em caso de erro
        $pdo->rollBack();
        // Exibir uma mensagem de erro (opcional)
        echo "Erro ao remover o produto: " . $e->getMessage();
    }
} else {
    // Redirecionar caso o ID não seja fornecido
    header("Location: gerenciar_produtos.php");
    exit();
}
?>
