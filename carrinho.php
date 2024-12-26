<?php
session_start();
require_once 'db/conexao.php'; // Ajuste o caminho conforme necessário
include $_SERVER['DOCUMENT_ROOT'] . '/cardapio-dinamico-semapi/header.php';

// Verifica se o usuário está logado
if (!isset($_SESSION['user_id'])) {
    echo "<h1>Você precisa estar logado para ver o carrinho.</h1>";
    require_once 'footer.php'; // Inclui o rodapé
    exit;
}

// Remover produto do carrinho
if (isset($_GET['remove_id'])) {
    $remove_id = $_GET['remove_id'];

    // Remove do carrinho na sessão
    if (array_key_exists($remove_id, $_SESSION['carrinho'])) {
        unset($_SESSION['carrinho'][$remove_id]);

        // Remover do banco de dados
        $usuario_id = $_SESSION['user_id'];
        try {
            $stmt = $pdo->prepare("DELETE FROM carrinho WHERE usuario_id = :usuario_id AND produto_id = :produto_id");
            $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
            $stmt->bindParam(':produto_id', $remove_id, PDO::PARAM_INT);
            $stmt->execute();
        } catch (PDOException $e) {
            echo "Erro ao remover produto do carrinho: " . $e->getMessage();
        }
    }
}

// Buscar produtos do carrinho no banco de dados
$usuario_id = $_SESSION['user_id'];
try {
    $stmt = $pdo->prepare("SELECT produto_id, quantidade FROM carrinho WHERE usuario_id = :usuario_id");
    $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
    $stmt->execute();
    $carrinho_db = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $_SESSION['carrinho'] = []; // Atualizar carrinho na sessão
    foreach ($carrinho_db as $item) {
        $_SESSION['carrinho'][$item['produto_id']] = $item['quantidade'];
    }
} catch (PDOException $e) {
    echo "Erro ao buscar produtos do carrinho: " . $e->getMessage();
}

?>

<div id="carrinho-container">
    <?php
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
                echo "<a href='?remove_id=" . $produto_id . "' class='remover-produto' title='Remover' style='position: absolute; top: 10px; right: 10px; color: #ff0000; font-size: 18px; font-weight: bold; text-decoration: none;'>✖</a>";
                echo "</div>";
                echo "</div>";
            }
        }

        echo "</div>";

        echo "<h2>Valor Total da Compra: R$ " . number_format($valor_total, 2, ',', '.') . "</h2>";
    }
    ?>
</div>

<?php if (!empty($_SESSION['carrinho'])): ?>
    <form id="compra-form" action="realizar_compra.php" method="post">
        <button type="button" id="btn-compra" style="background-color: #28a745; color: white; padding: 10px 20px; border: none; font-size: 16px; cursor: pointer;">Realizar Compra</button>
    </form>
<?php endif; ?>

<?php require_once 'footer.php'; ?>
<script>
    document.getElementById('btn-compra').addEventListener('click', function (e) {
        e.preventDefault();

        // Fazer a verificação dos produtos via AJAX
        fetch('verificar_produtos.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Se todos os produtos estão disponíveis, redireciona para realizar_compra.php
                document.getElementById('compra-form').submit();
            } else if (data.produtos_faltando) {
                // Exibir alerta com os IDs dos produtos que estão faltando
                alert("Os seguintes produtos não estão mais disponíveis e foram removidos do carrinho:\n" + data.produtos_faltando.join(", "));

                // Recarregar os itens do carrinho dinamicamente
                fetch('/recarregar_carrinho.php', {
                    method: 'GET'
                })
                .then(response => response.text())
                .then(html => {
                    // Atualiza o carrinho no DOM
                    document.getElementById('carrinho-container').innerHTML = html;
                })
                .catch(error => {
                    console.error("Erro ao recarregar o carrinho:", error);
                    alert("Ocorreu um erro ao recarregar o carrinho. Tente novamente.");
                });
            } else if (data.error) {
                // Exibir mensagem de erro geral
                alert("Erro: " + data.error);
            }
        })
        .catch(error => {
            console.error("Erro na verificação dos produtos:", error);
            alert("Ocorreu um erro ao verificar os produtos. Tente novamente.");
        });
    });
    
</script>
<!-- Inclua o script.js e garanta que o contador seja atualizado -->
<script src="/cardapio-dinamico-semapi/assets/js/script.js"></script>
<script>
    // Chama a função para atualizar o contador do carrinho ao carregar a página
    document.addEventListener('DOMContentLoaded', () => {
        atualizarContadorCarrinho();
    });
</script>