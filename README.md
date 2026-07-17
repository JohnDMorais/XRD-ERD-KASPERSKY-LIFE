# BitLocker CBC Enforcement + Wazuh Kaspersky Integration

## Visão Geral

Este repositório reúne automações voltadas para segurança da informação, contemplando:

* **Script de migração e padronização do BitLocker** para criptografia **AES-256 CBC**.
* **Decoders personalizados do Wazuh** para eventos do Kaspersky.
* **Rules personalizadas do Wazuh** para correlação e detecção de eventos provenientes do Kaspersky.

O objetivo é facilitar a implantação de controles de segurança em ambientes corporativos, mantendo configurações padronizadas e permitindo melhor visibilidade dos eventos de endpoint.

---

# Estrutura do Repositório

```text
.
├── bitlocker/
│   └── bitlocker_cbc_enforce.ps1
│
├── wazuh/
│   ├── decoders/
│   │   └── kaspersky_decoder.xml
│   │
│   └── rules/
│       └── kaspersky_rules.xml
│
└── README.md
```

---

# BitLocker CBC Enforcement

## Objetivo

O script realiza a migração automática de estações Windows para o algoritmo **AES-256 CBC**, garantindo conformidade com políticas corporativas que não utilizam **XTS-AES**.

Todo o processo foi desenvolvido para ser **idempotente**, ou seja, pode ser executado diversas vezes sem causar alterações caso o equipamento já esteja em conformidade.

---

## Fluxo de Execução

O script executa as seguintes etapas:

1. Verifica o status atual do BitLocker.
2. Identifica se o volume já utiliza AES-256 CBC.
3. Caso necessário:

   * inicia a descriptografia do volume;
   * acompanha o progresso até sua conclusão.
4. Configura as políticas de criptografia via Registro do Windows.
5. Executa atualização das políticas (`gpupdate`).
6. Reinicia o equipamento.
7. Após o reboot:

   * adiciona o protetor TPM;
   * habilita o BitLocker;
   * cria Recovery Password;
   * inicia nova criptografia utilizando AES-256 CBC.
8. Valida o resultado final.

---

## Características

* Execução idempotente.
* Registro detalhado em log.
* Controle de reboot.
* Continuação automática após reinicialização.
* Tratamento de erros.
* Timeout durante descriptografia.
* Validação da criptografia aplicada.

---

## Log

Durante a execução é criado o arquivo:

```text
C:\Windows\Temp\bitlocker_cbc_enforce.log
```

---

## Arquivo de Controle

Para controlar a execução entre reinicializações é utilizado:

```text
C:\ProgramData\BitLockerMigration\reencrypt.flag
```

Este arquivo é removido automaticamente ao término da migração.

---

# Wazuh - Integração Kaspersky

Também fazem parte deste repositório os arquivos necessários para integração do **Kaspersky** com o **Wazuh**.

## Decoders

Os decoders realizam a interpretação dos logs enviados pelo Kaspersky, extraindo campos relevantes para posterior correlação.

Exemplos de informações extraídas:

* Nome do equipamento
* Usuário
* Tipo do evento
* Severidade
* Malware detectado
* Caminho do arquivo
* Processo
* Resultado da ação
* Engine do antivírus

---

## Rules

As rules personalizadas realizam a classificação e correlação dos eventos processados pelos decoders, atribuindo níveis de severidade, grupos de eventos e mapeamento MITRE ATT&CK quando aplicável.

As regras contemplam eventos do **Kaspersky Endpoint Security (KES)** e do **Kaspersky Security Center (KSC)**, incluindo:

### Proteção Antimalware

* Detecção de malware.
* Objetos suspeitos.
* Objetos bloqueados.
* Malware removido.
* Malware não removido.
* Objetos excluídos.
* Arquivos restaurados/backup.
* Arquivos protegidos por senha.
* Malware detectado e reportado.
* Malware detectado e permitido.

### Proteção Web

* URLs bloqueadas.
* URLs classificadas como suspeitas.
* Bloqueios realizados pelo Kaspersky Security Network (KSN).

### Controle de Aplicações

* Execução de aplicações bloqueadas.
* Eventos relacionados ao controle de aplicações.

### Controle de Dispositivos

* Dispositivo conectado.
* Dispositivo removido.
* Conexão de dispositivo negada.

### Detecção de Ataques

* Network Attack Blocker.
* Tentativas de reconhecimento de rede.
* Detecção de ataques de rede.
* Eventos classificados como *attack*.

### Proteção Contra Manipulação

* Eventos relacionados à tentativa de desativação ou alteração dos mecanismos de proteção.
* Detecções associadas às técnicas MITRE ATT&CK de evasão de defesa.

### Administração do Kaspersky Security Center (KSC)

As regras também monitoram eventos administrativos do Kaspersky Security Center, incluindo:

* Autenticação bem-sucedida.
* Falhas de autenticação.
* Atualização das bases antivírus.
* Hosts não visíveis.
* Hosts em estado de alerta.
* Hosts em estado crítico.
* Alteração de tarefas.
* Execução de tarefas.
* Inclusão, alteração e remoção de políticas.
* Inclusão e remoção de grupos administrativos.
* Movimentação de hosts entre grupos.
* Inclusão de pacotes de instalação.
* Criação de relatórios.
* Eventos de licenciamento.
* Detecção de excesso de eventos (Spam Events).

### MITRE ATT&CK

Sempre que possível, as regras realizam o mapeamento para técnicas do MITRE ATT&CK, incluindo, entre outras:

* T1204 – User Execution
* T1562 – Impair Defenses
* T1046 – Network Service Discovery
* T1016 – System Network Configuration Discovery
* T1049 – System Network Connections Discovery
* T1110 – Brute Force
* T1078 – Valid Accounts
* T1072 – Software Deployment Tools
* T1200 – Hardware Additions
* T1587.003 – Malware Development

Os níveis de severidade das regras variam conforme a criticidade do evento, permitindo priorização dos alertas e melhor integração com processos de monitoramento e resposta a incidentes.


---

# Requisitos

## BitLocker

* Windows 10 ou Windows 11
* BitLocker habilitado
* TPM compatível
* PowerShell executado como Administrador

## Wazuh

* Wazuh Manager
* Integração de envio de logs do Kaspersky
* Permissão para inclusão de decoders e rules customizadas

---

# Objetivo do Projeto

Este projeto busca automatizar tarefas recorrentes de segurança, reduzindo esforço operacional e padronizando controles de proteção em ambientes corporativos.

As automações podem servir como base para implantação em larga escala, adequação a requisitos de compliance e integração com plataformas SIEM.

---

# Licença

Este projeto pode ser utilizado, adaptado e expandido conforme a necessidade da organização, respeitando as políticas internas de segurança e governança.
