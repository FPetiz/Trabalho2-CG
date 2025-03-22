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

* Um ambiente que suporte shaders GLSL, como VSCode, para isso serão necessárias as seguintes extensões:
    * Shader Toy 
    * Shader languages support for VS Code
* Texturas:
    * `Grass004_1K-JPG_Color.jpg`
    * `Metal014_1K-JPG_Color.jpg`
    * `Leather030_1K-JPG_Color.jpg`
    * As texturas foram tiradas deste site: [https://ambientcg.com/](https://ambientcg.com/).

## Como Usar

1.  **Clone o repositório Git:**

    * Se você tiver o Git instalado, clone o repositório para o seu computador usando o seguinte comando:

        ```bash
        git clone https://github.com/FPetiz/Trabalho2-CG.git
        ```

2.  **Abra o shader em um ambiente que suporte GLSL.**

    * Você pode usar o Visual Studio Code.

3.  **Para visualizar o shader.**

    * No caso do VSCode:
    1. Clique com o botão direito em qualquer parte do código;
    2. Clique em "Shader Toy: Show GLSL Preview".

## Autora

* Fernanda Cardoso Petiz