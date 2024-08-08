# Monitoramento de ruídos

#### Criação de um aplicativo para a monitoração de ruídos utilizando um microfone e uma câmera conectados em uma Raspberry Pi 3.

[Objetivos](#objetivos)

[Sensores Utilizados](#sensores-utilizados)

[Tecnologias Utilizadas](#sensores-utilizados)

[Como Utilizar](#como-utilizar)


![Home](/assets/home.png)
![Gráficos](/assets/graficos.png)
![Vídeos](/assets/videos.png)
![Filtros](/assets/filtros.png)

## Objetivos
Esse projeto foi desenvolvido por mim durante uma iniciação científica na Universidade Federal de Santa Catarina (UFSC) com o objetivo de captar e armazenar ruídos provocados em uma malha ferroviária. Os dados obtidos pelo microfone em decibéis (dB) e os vídeos gravados pela câmera são armazenados em um banco de dados na Raspberry Pi, e por meio do aplicativo pode-se visualizar tais dados em tempo real, baixar todos os dados do banco de dados e visualizar os vídeos obtidos.

## Sensores Utilizados
O protocolo de comunicação entre o microfone e a Raspberry é o Modbus RTU, com o padrão RS-485. Foi utilizado um adaptador conversor RS-485 para USB a fim de que a obtenção dos dados fosse facilitada na Raspberry.
A câmera, de modo semelhante, também foi conectado na Raspberry através da porta USB.

## Tecnologias Utilizadas
* Criação do backend e da captu dos dados contruídos em Rust.
* Interface feita em Dart, utilizando o framework Flutter.
* Utilização do serviço Zrok para a criação de túneis para expor o backend local na Raspberry Pi para a internet.
* Banco de dados (PostgreSQL) e aplicação containerizada com Docker

## Como utilizar

1. Ao conectar a Raspberry Pi na energia, um script feito em Python irá mandar o IP dela através do email do projeto. Esse IP será utilizado para a comunicação por SSH, a fim de que se possa inicializar o servidor e o código dos sensores. Dessa maneira, em um computador que esteja na mesma rede de internet da Raspberry:
```
# Clone esse repositório
git clone https://github.com/lucas-bernardino/ufsc-iniciacao-cientifica.git

# Entre na pasta do repositório
cd ufsc-iniciacao-cientifica

# Rode o script para obter o IP da Raspberry
python3 ui/get_ip.py
```
Para utilizar esse script, você precisa ter o Python instalado e a colocar a senha do GMAIL no arquivo .env na pasta *ui* assim como está exemplficado no arquivo .env.example.

2. Após obter o IP, abra outra janela no terminal e conecte-se na Raspberry através do SSH:
```
# Substituia <ip-raspberry> pelo IP obtido anteriormente
ssh pi@<ip-raspberry> 
```

3. No terminal da Raspberry, é preciso inicializar o servidor e a acquisição de dados. Há um arquivo chamado *server_init.sh* que você deve executar para que o backend, banco de dados, zrok e script para envio da URL pelo email sejam iniciados. 
```
# Rode o seguinte comando:
./server_init.sh
```
Após incializar, é preciso abrir outra janela e entrar novamente por SSH e rodar o script que inicia a acquisição de dados
```
# Em outro terminal, rode:
./sensor_init.sh
```

4. Ao concluir o passo 3, você pode fechar os terminais pois o setup inicial da Raspberry já está concluído. Agora, é preciso *buildar* o código em Flutter com a URL obtida ao iniciar o servidor. Assim, na aba do terminal do passo 1:
```
# Rode o script responsável por atualizar a URL da API no .env
python3 ui/handle_api_url.py
```

5. Feito isso, você pode buildar a interface. Para isso, é necessário ter o Dart e Flutter instalado. Após a instalação deles, obtenha o executável da interface: 
```
# Navegue para a pasta
cd ui

# Atualize e obtenha as dependências do projeto
flutter pub get

# Build
flutter build windows
```
O executável estará localizado dentro da pasta *ui/build/windows/runner/Release*