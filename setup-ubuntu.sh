#!/bin/bash

# Get the directory where the script is located
current_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Check the current shell using the $SHELL environment variable
if [[ "$SHELL" == */zsh ]]; then
    config_file="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    config_file="$HOME/.bashrc"
else
    echo "Unsupported shell. This script supports Bash and Zsh."
    exit 1
fi

# Check if the current directory is already in the PATH
if ! grep -q "export PATH=.*$current_dir" "$config_file"; then
    # Add the directory to the PATH
    echo "export PATH=\$PATH:$current_dir" >> "$config_file"
    echo "Current directory ($current_dir) added to PATH in $config_file."
else
    echo "Current directory ($current_dir) is already in the PATH."
fi

# Apply changes based on the shell
if [[ "$config_file" == *".zshrc" ]]; then
    source "$HOME/.zshrc"
elif [[ "$config_file" == *".bashrc" ]]; then
    source "$HOME/.bashrc"
fi

# Verifica se o script está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    whiptail --title "Erro" --msgbox "Este script deve ser executado como root." 8 78
    exit 1
fi


# Atualiza o sistema
echo "Atualizando o sistema..."
# apt update && apt upgrade -y

# Instala Programas Essenciais
install_essentials() {
    echo "Instalando programas essenciais..."
    # Instalar utilitários básicos
    apt install -y vim curl wget gdebi htop gnome-tweaks gparted snapd usb-creator-gtk imagemagick gnupg lsb-release
    # Instalar codecs de mídia
    apt install -y ubuntu-restricted-extras
    # Instalar suporte a arquivos compactados
    apt install -y unzip zip
    # Instalar suporte a Flatpak
    apt install -y flatpak
    apt install -y gnome-software-plugin-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # Instalar drivers adicionais (isso abrirá uma janela GUI)
    ubuntu-drivers autoinstall
}

# Instala App Image Launcher
install_app_image_launcher() {
    echo "Instalando App Image Launcher..."
    local url=$(curl -s https://api.github.com/repos/TheAssassin/AppImageLauncher/releases/latest \
                | grep browser_download_url \
                | grep 'bionic_amd64.deb' \
                | cut -d '"' -f 4)

    if [ -z "$url" ]; then
        echo "Não foi possível encontrar a URL de download do App Image Launcher."
        return
    fi

    wget "$url" -O appimagelauncher.deb
    dpkg -i appimagelauncher.deb
    rm appimagelauncher.deb
    echo "App Image Launcher instalado com sucesso."
}

# Instala Ferramentas de Desenvolvimento
install_development_tools() {
    echo "Instalando ferramentas de desenvolvimento..."
    apt install -y git nodejs npm build-essential cmake python3-pip apt-transport-https ca-certificates software-properties-common \
        python3-setuptools python-setuptools php android-tools-adb android-tools-fastboot
    snap install android-studio --classic
    snap install phpstorm --classic
    snap install postman
    snap install beekeeper-studio
}

install_office_and_multimedia(){
    echo "Instalando Ferramentas Multimídia e de Escritório..."
    apt install -y kdenlive peek obs-studio vlc flameshot libreoffice-writer libreoffice-calc
    snap install notion-snap-reborn spotify
}

# Configura Git
configure_git() {
    echo "Configurando Git..."
    read -p "Digite seu nome: " name
    read -p "Digite seu email: " email
    git config --global core.fileMode false
    git config --global user.name "$name"
    git config --global user.email "$email"
    echo "Git configurado."
    git config --list
}

# Configura Extensões do VS Code
configure_vscode() {
    echo "Configurando extensões do VS Code..."
    snap install code --classic
    # Verifica se o VS Code foi instalado com sucesso
    if ! command -v code &> /dev/null; then
        echo "VS Code não está instalado. Pulando instalação de extensões..."
        return
    fi

    local extensions=(
        ms-python.python
        monokai.theme-monokai-pro-vscode
        PKief.material-icon-theme
        eamodio.gitlens
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-containers
        ms-vscode-remote.vscode-remote-extensionpack
        Dart-Code.flutter
        alexisvt.flutter-snippets
        Dart-Code.dart-code
        GitHub.copilot
    )

    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --no-sandbox --user-data-dir=/home/luiz/ || echo "Falha ao instalar extensão $ext"
    done
}

# Função para clonar repositórios e adicionar ao .zshrc
clone_and_setup() {
    local repo_url="$1"
    local dest_dir="$2"
    local source_line="$3"

    # Verifica se o diretório do plugin já existe
    if [ ! -d "$dest_dir" ]; then
        git clone "$repo_url" "$dest_dir" || { echo "Falha ao clonar $repo_url"; return 1; }
    fi

    # Adiciona a linha de configuração ao .zshrc se não estiver lá
    if ! grep -qF "$source_line" ~/.zshrc; then
        echo "$source_line" >> ~/.zshrc
    fi
}

# Instala e Configura ZSH com powerlevel10k
install_zsh() {
    echo "Instalando e configurando ZSH..."
    apt install -y zsh

    # Instala Oh My Zsh e o tema powerlevel10k
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        || echo "Falha ao instalar Oh My Zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH:-~/.oh-my-zsh}/themes/powerlevel10k \
        || echo "Falha ao clonar powerlevel10k"

    local ZSHRC="$HOME/.zshrc"
    local NEW_THEME='ZSH_THEME="powerlevel10k/powerlevel10k"'
    if [ -f "$ZSHRC" ]; then
        sed -i.bak "/^ZSH_THEME=/c\\$NEW_THEME" "$ZSHRC"
        p10k configure
        echo "Tema ZSH atualizado para $NEW_THEME em $ZSHRC"
    else
        echo "Arquivo .zshrc não encontrado em $ZSHRC"
    fi

    # Instala o plugin zsh-autosuggestions
    clone_and_setup "https://github.com/zsh-users/zsh-autosuggestions" \
                    "$HOME/.zsh/zsh-autosuggestions" \
                    "source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

    # Instala o plugin zsh-syntax-highlighting
    clone_and_setup "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
                    "$HOME/.zsh/zsh-syntax-highlighting" \
                    "source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # Instala o plugin zsh-completions
    clone_and_setup "https://github.com/zsh-users/zsh-completions.git" \
                    "$HOME/.zsh/zsh-completions" \
                    "source $HOME/.zsh/zsh-completions/zsh-completions.zsh"
    
}

install_google_chrome(){
    echo "Instalando Google Chrome..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
}

install_communicators(){
    echo "Instalando Ferramentas de Comunicação..."
    snap install slack --classic
    snap install discord --classic
}

install_network_tools(){
    echo "Instalando Ferramentas de Rede..."
    apt install -y nmap net-tools
}

install_grub_theme(){
    sudo grub-install /dev/sda
    sudo update-grub

    echo "Instalando Tema do Grub..."
    git clone https://github.com/vinceliuice/grub2-themes.git
    cd grub2-themes
    sudo ./install.sh -b -t tela
    cd ..

    sudo apt install plymouth libplymouth5 plymouth-label
    git clone https://github.com/emanuele-scarsella/vortex-ubuntu-plymouth-theme.git
    cd vortex-ubuntu-plymouth-theme
    sudo chmod +x install
    sudo ./install
    sudo reboot 3
}


# Menu Principal
while true; do
    CHOICE=$(whiptail --title "Menu de Instalação" --menu "Escolha uma opção:" 20 78 12 \
        "1" "Instalar Programas Essenciais" \
        "2" "Instalar App Image Launcher" \
        "3" "Instalar Ferramentas de Desenvolvimento" \
        "4" "Configurar Git" \
        "5" "Configurar VS Code" \
        "6" "Instalar e Configurar ZSH" \
        "7" "Instalar Google Chrome" \
        "8" "Instalar Ferramentas de Comunicação" \
        "9" "Instalar Ferramentas de Rede" \
        "10" "Instalar Ferramentas de escritório" \
        "11" "Instalar Docker" \
        "12" "Instalar Tema do Mac" \
        "13" "Instalar Tema do Grub" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        break
    fi

    # Chama a função com base na escolha
    case $CHOICE in
        1) install_essentials ;;
        2) install_app_image_launcher ;;
        3) install_development_tools ;;
        4) configure_git ;;
        5) configure_vscode ;;
        6) install_zsh ;;
        7) install_google_chrome ;;
        8) install_communicators ;;
        9) install_network_tools ;;
        10) install_office_and_multimedia ;;
        11) curl -sL https://gist.githubusercontent.com/luizalbertobm/5f47ae9813115549ecebd841eb6580f0/raw/15bd647ee44a0f27f0e8957c98bcff75db9e332d/install_docker.sh | sudo bash ;;
        12) curl -sL https://gist.githubusercontent.com/luizalbertobm/f9331f25211732752e77e7065b72acca/raw/b656c7395b0aed141eac478fbc3f39bd8fa82e4c/installMacTheme.sh | sudo bash ;;
        13) install_grub_theme ;;
    esac
done

# Limpeza e Reinicialização (opcional)
if (whiptail --title "Reinicialização" --yesno "Deseja reiniciar o sistema?" 10 60); then
    echo "O sistema será reiniciado em 5 segundos..."
    sleep 5
    reboot
else
    echo "Reinicialização do sistema abortada."
fi