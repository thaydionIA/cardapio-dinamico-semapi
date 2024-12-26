<?php
ob_start(); // Inicia o buffer de saída
session_start();
require_once 'db/conexao.php'; // Ajuste o caminho conforme necessário
include $_SERVER['DOCUMENT_ROOT'] . '/cardapio-dinamico-semapi/header.php'; // Inclua o cabeçalho se necessário

// Verifica se o usuário está logado e se o carrinho não está vazio
if (!isset($_SESSION['user_id']) || empty($_SESSION['carrinho'])) {
    echo "<h1>Você precisa ter itens no carrinho para realizar a compra.</h1>";
    include 'footer.php'; // Inclui o rodapé
    exit;
}

$valor_total = 0; // Calcula o valor total do carrinho
foreach ($_SESSION['carrinho'] as $produto_id => $quantidade) {
    // Consultar o preço do produto no banco de dados
    $stmt = $pdo->prepare("SELECT preco FROM produtos WHERE id = :id");
    $stmt->bindParam(':id', $produto_id);
    $stmt->execute();
    $produto = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($produto) {
        $subtotal = $produto['preco'] * $quantidade;
        $valor_total += $subtotal;
    }
}

// Verifica se o formulário foi enviado e processa o pagamento
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['forma_pagamento'])) {
    $forma_pagamento = $_POST['forma_pagamento'];

    // Insere a venda na tabela vendas com status 'Pendente'
    $stmt_venda = $pdo->prepare("INSERT INTO vendas (cliente_id, total, status, status_pedido) VALUES (:cliente_id, :total, 'Pendente', 'Pedido Feito')");
    $stmt_venda->bindParam(':cliente_id', $_SESSION['user_id']);
    $stmt_venda->bindParam(':total', $valor_total);
    $stmt_venda->execute();

    // Obtém o ID da venda recém-criada
    $venda_id = $pdo->lastInsertId();

    // Insere os itens da venda na tabela itens_venda
    foreach ($_SESSION['carrinho'] as $produto_id => $quantidade) {
        $stmt_item_venda = $pdo->prepare("INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco) VALUES (:venda_id, :produto_id, :quantidade, (SELECT preco FROM produtos WHERE id = :produto_id))");
        $stmt_item_venda->bindParam(':venda_id', $venda_id);
        $stmt_item_venda->bindParam(':produto_id', $produto_id);
        $stmt_item_venda->bindParam(':quantidade', $quantidade);
        $stmt_item_venda->execute();
    }

    // Redireciona para a página de sucesso correspondente
    switch ($forma_pagamento) {
        case 'pix':
            header("Location: sucesso_pix.php");
            break;
        case 'credito':
            header("Location: sucesso_credito.php");
            break;
        case 'dinheiro':
            header("Location: sucesso_dinheiro.php");
            break;
        default:
            echo "<h1>Forma de pagamento inválida. Por favor, selecione uma opção válida.</h1>";
            exit;
    }
    exit;
}
?>

<h1>Escolha a Forma de Pagamento</h1>
<p>Valor Total da Compra: R$ <?php echo number_format($valor_total, 2, ',', '.'); ?></p>

<form action="realizar_compra.php" method="post">
    <input type="hidden" name="valor_total" value="<?php echo $valor_total; ?>">
    <label>
        <input type="radio" name="forma_pagamento" value="pix" required>
        Pagamento via PIX
    </label>
    <br>
    <label>
        <input type="radio" name="forma_pagamento" value="credito" required>
        Pagamento via Cartão de Crédito
    </label>
    <br>
    <label>
        <input type="radio" name="forma_pagamento" value="dinheiro" required>
        Pagamento em Dinheiro
    </label>
    <br><br>
    <button type="submit" style="background-color: #28a745; color: white; padding: 10px 20px; border: none; font-size: 16px; cursor: pointer;">Confirmar Pagamento</button>
</form>

<script src="assets/js/script.js"></script>
<?php
include 'footer.php'; // Inclua o rodapé se necessário
ob_end_flush(); // Envia todo o conteúdo do buffer
?>
