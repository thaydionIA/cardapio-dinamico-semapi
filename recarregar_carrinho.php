<?php
session_start();
require_once 'db/conexao.php';

$usuario_id = $_SESSION['user_id'];

// Buscar produtos do carrinho no banco de dados
try {
    $stmt = $pdo->prepare("SELECT produto_id, quantidade FROM carrinho WHERE usuario_id = :usuario_id");
    $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
    $stmt->execute();
    $carrinho_db = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $_SESSION['carrinho'] = [];
    foreach ($carrinho_db as $item) {
        $_SESSION['carrinho'][$item['produto_id']] = $item['quantidade'];
    }
} catch (PDOException $e) {
    echo "<p>Erro ao buscar produtos do carrinho: " . $e->getMessage() . "</p>";
    exit;
}

if (empty($_SESSION['carrinho'])) {
    echo "<h1>Carrinho Vazio</h1>";
    echo "<p>Você ainda não adicionou produtos ao carrinho.</p>";
} else {
    echo "<h1>Produtos no Carrinho</h1>";
    echo "<div class='produtos-container'>";

    $valor_total = 0;

    foreach ($_SESSION['carrinho'] as $produto_id => $quantidade) {
        $stmt = $pdo->prepare("SELECT nome, preco, imagem FROM produtos WHERE id = :id");
        $stmt->bindParam(':id', $produto_id, PDO::PARAM_INT);
        $stmt->execute();
        $produto = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($produto) {
            $subtotal = $produto['preco'] * $quantidade;
            $valor_total += $subtotal;

            echo "<div class='produto-item' style='position: relative; padding: 15px; border: 1px solid #ddd; margin-bottom: 10px;'>";
            echo "<div class='produto-imagem'>";
            if ($produto['imagem']) {
                echo "<img src='/cardapio-dinamico-semapi/admin/uploads/produtos/" . htmlspecialchars($produto['imagem']) . "' alt='" . htmlspecialchars($produto['nome']) . "'>";
            }
            echo "</div>";
            echo "<div class='produto-info'>";
            echo "<h3>" . htmlspecialchars($produto['nome']) . "</h3>";
            echo "<p>Quantidade: " . $quantidade . "</p>";
            echo "<p>Preço Unitário: R$ " . number_format($produto['preco'], 2, ',', '.') . "</p>";
            echo "<p>Subtotal: R$ " . number_format($subtotal, 2, ',', '.') . "</p>";
            echo "</div>";
            echo "</div>";
        }
    }

    echo "</div>";
    echo "<h2>Valor Total da Compra: R$ " . number_format($valor_total, 2, ',', '.') . "</h2>";
}
?>
