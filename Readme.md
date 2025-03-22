## Reconhecimento
Este trabalho foi desenvolvido com base na estrutura do shader "Newton Pendulum" criado por leesten em Janeiro de 2022 e está disponível em [www.shadertoy.com/view/7sXyzX](https://www.shadertoy.com/view/7sXyzX). 

# Cena de Campo de Futebol Dinâmica com Ray Marching

Este projeto implementa uma cena de campo de futebol dinâmica utilizando a técnica de ray marching em um shader GLSL. A cena simula um campo de futebol simples ao longo de um dia, com iluminação e reflexos.

## Funcionalidades

* **Campo de Futebol**: Modelagem de um campo de futebol com goleiras, bola e linhas do campo.
* **Iluminação Dinâmica**: Simulação do ciclo dia-noite através da movimentação do sol e alteração da cor do céu.
* **Materiais Realistas**: Aplicação de texturas e cálculos de reflexão para simular diferentes materiais, como grama, metal e couro.
* **Sombras e Reflexos**: Cálculo de sombras e reflexos para adicionar profundidade e realismo à cena.

## Dependências

* Um ambiente que suporte shaders GLSL, como VSCode com as extensões "Shader Toy" e "Shader languages support for VS Code".
* Texturas:
    * `Grass004_1K-JPG_Color.jpg`
    * `Metal014_1K-JPG_Color.jpg`
    * `Leather030.png`
    * As texturas foram tiradas deste site: https://ambientcg.com/.

## Como Usar

1.  **Clone o repositório Git:**

    * Se você tiver o Git instalado, clone o repositório para o seu computador usando o seguinte comando:

        ```bash
        git clone [https://github.com/FPetiz/Trabalho2-CG.git](https://github.com/FPetiz/Trabalho2-CG.git)
        ```

2.  **Abra o shader em um ambiente que suporte GLSL.**

    * Você pode usar o Visual Studio Code.

3.  **Ajuste as variáveis `iResolution` e `iMouse` conforme necessário.**

    * Essas variáveis controlam a resolução da tela e a posição do mouse, respectivamente.

4.  **Compile e execute o shader.**

    * O processo de compilação e execução dependerá do ambiente que você está usando.

## Autora

* \[Fernanda Cardoso Petiz]