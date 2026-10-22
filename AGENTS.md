# Contexto do projeto

## Objetivo
Criar ilhas de aprendizado de inglês

## Stack tecnológica
- Linguagem: Dart
- Frameworks: Flutter com Material UI
- Banco de dados: SQLite

## Arquitetura
- Seguir a arquitetura Hexagonal e MVVM.
- Separar responsabilidades por camadas: Models, Repository, Service, View Models, Views
- Respeitar os princípios SOLID.

## Regras de desenvolvimento
- Seguir padrão KISS.
- Reutilizar componentes existentes.
- Evitar duplicação de código.
- Não adicionar dependências sem necessidade.
- Não alterar contratos de API sem autorização.
- Criar testes para novas regras de negócio.

## Antes de alterar código
- Identificar os componentes envolvidos.
- Verificar dependências e efeitos colaterais.
- Explicar brevemente a abordagem.
- Implementar a menor alteração necessária.