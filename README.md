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

As rules utilizam os eventos decodificados para gerar alertas de segurança no Wazuh.

Entre as detecções disponíveis podem estar:

* Malware detectado
* Malware removido
* Malware bloqueado
* Arquivos colocados em quarentena
* Falha na remoção
* Atualização de banco de assinaturas
* Alterações de política
* Eventos críticos do Endpoint Security
* Eventos de Network Attack Blocker
* Detecções de comportamento suspeito
* Eventos de proteção em tempo real

As regras podem ser adaptadas conforme a política de monitoramento da organização.

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
