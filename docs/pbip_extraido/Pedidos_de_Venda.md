# Modelo semantico: Pedidos de Venda

- Tabelas: 6
- Colunas: 170
- Medidas DAX: 0
- Relacionamentos: 5 (1 inativos, 0 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| PEDIDOSEMBARQUE | 36 | 0 |
| dAgrupPROD | 3 | 0 |
| dCalendar | 114 | 0 |
| dDescReduz | 4 | 0 |
| dRegiao | 3 | 0 |
| dTempo | 10 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| PEDIDOSEMBARQUE.EMISSAONF | dCalendar.Data | many->one | singleDirection | sim |
| PEDIDOSEMBARQUE.PRODUTO | dAgrupPROD.PRODUTO | many->one | singleDirection | sim |
| PEDIDOSEMBARQUE.ESTADO | dRegiao.UF | many->one | singleDirection | sim |
| PEDIDOSEMBARQUE.CODPROD | dDescReduz.Codigo | many->one | singleDirection | sim |
| PEDIDOSEMBARQUE.EMISSAOPED | dCalendar.Data | many->one | singleDirection | nao |

## Medidas DAX
