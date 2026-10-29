#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
#  Instalador automático - OffTec AI (Termux)
#  Uso:
#    git clone https://github.com/SEU_USUARIO/SEU_REPO.git
#    cd SEU_REPO
#    bash install.sh
# ==========================================================

set -e

# ---------- Configurações ----------
LLAMA_REPO="https://github.com/ggml-org/llama.cpp.git"
OFFTEC_REPO="https://github.com/Mcsd7/OffTecAI.git"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q2_k.gguf"

LLAMA_DIR="$HOME/llama.cpp"
OFFTEC_DIR="$HOME/OffTecAI"
MODEL_DIR="$HOME/modelos/qwen"
MODEL_FILE="$MODEL_DIR/qwen.gguf"

# ---------- Cores ----------
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
AZUL="\033[1;34m"
RESET="\033[0m"

etapa() { echo -e "\n${AZUL}==> $1${RESET}"; }
ok()    { echo -e "${VERDE}✔ $1${RESET}"; }
aviso() { echo -e "${AMARELO}! $1${RESET}"; }
erro()  { echo -e "${VERMELHO}✘ $1${RESET}"; exit 1; }

trap 'erro "Algo deu errado na linha $LINENO. Corrija o problema e rode: bash install.sh (ele continua de onde parou)."' ERR

# ---------- Verificação do ambiente ----------
if ! command -v pkg >/dev/null 2>&1; then
    erro "Este script foi feito para o Termux (comando 'pkg' não encontrado)."
fi

echo -e "${VERDE}"
echo "=========================================="
echo "        Instalador OffTec AI - Termux      "
echo "=========================================="
echo -e "${RESET}"

# ---------- 1) Atualizar o Termux ----------
etapa "1/9 Atualizando o Termux"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg upgrade -y -o Dpkg::Options::="--force-confold"
ok "Termux atualizado"

# ---------- 2) Dependências ----------
etapa "2/9 Instalando dependências"
pkg install -y python git cmake clang make curl
ok "Dependências instaladas"

# ---------- 3) Baixar o llama.cpp ----------
etapa "3/9 Baixando o llama.cpp"
if [ -d "$LLAMA_DIR/.git" ]; then
    aviso "llama.cpp já existe, pulando download"
else
    git clone "$LLAMA_REPO" "$LLAMA_DIR"
    ok "llama.cpp baixado"
fi

# ---------- 4) Compilar o llama.cpp ----------
etapa "4/9 Compilando o llama.cpp (pode demorar vários minutos)"
if [ -x "$LLAMA_DIR/build/bin/llama-server" ] && [ -x "$LLAMA_DIR/build/bin/llama-cli" ]; then
    aviso "llama.cpp já compilado, pulando compilação"
else
    cd "$LLAMA_DIR"
    cmake -B build
    cmake --build build --target llama-server llama-cli -j 2
    ok "llama.cpp compilado"
fi

# ---------- 5) Pasta do modelo ----------
etapa "5/9 Criando a pasta do modelo"
mkdir -p "$MODEL_DIR"
ok "Pasta criada: $MODEL_DIR"

# ---------- 6) Baixar o modelo Qwen ----------
etapa "6/9 Baixando o modelo Qwen 2.5 0.5B"
TAMANHO_MIN=1000000  # 1 MB: abaixo disso consideramos o arquivo inválido
if [ -f "$MODEL_FILE" ] && [ "$(stat -c%s "$MODEL_FILE")" -gt "$TAMANHO_MIN" ]; then
    aviso "Modelo já baixado, pulando download"
else
    curl -L --fail --retry 3 -C - -o "$MODEL_FILE" "$MODEL_URL"
    ok "Modelo baixado"
fi

# ---------- 7) Conferir o download ----------
etapa "7/9 Conferindo o download"
if [ ! -f "$MODEL_FILE" ] || [ "$(stat -c%s "$MODEL_FILE")" -le "$TAMANHO_MIN" ]; then
    rm -f "$MODEL_FILE"
    erro "O modelo não foi baixado corretamente. Verifique a internet e rode o script de novo."
fi
ls -lh "$MODEL_FILE"
ok "Modelo conferido"

# ---------- 8) Baixar o OffTec AI ----------
etapa "8/9 Baixando o OffTec AI"
if [ -d "$OFFTEC_DIR/.git" ]; then
    aviso "OffTec AI já existe, atualizando"
    cd "$OFFTEC_DIR"
    git pull --ff-only || aviso "Não foi possível atualizar, usando a versão atual"
else
    git clone "$OFFTEC_REPO" "$OFFTEC_DIR"
    ok "OffTec AI baixado"
fi

# ---------- 9) Iniciar a IA ----------
etapa "9/9 Iniciando a IA"
echo
echo -e "${VERDE}Instalação concluída!${RESET}"
echo -e "Abra no navegador do celular: ${AMARELO}http://127.0.0.1:8765${RESET}"
echo -e "Para parar a IA, aperte ${AMARELO}CTRL + C${RESET}."
echo -e "Para iniciar de novo depois, rode: ${AMARELO}cd ~/OffTecAI && python offtec_web.py${RESET}"
echo

trap - ERR
cd "$OFFTEC_DIR"
exec python offtec_web.py
