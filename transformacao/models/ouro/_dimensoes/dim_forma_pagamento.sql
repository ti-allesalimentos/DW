/*
  Dimensao forma de pagamento. SX5010 e uma tabela generica de
  parametrizacao do Protheus (varias listas de codigo discriminadas por
  x5_tabela); '58' e a tabela de forma de pagamento (sqlFormPgto).
*/

with formas as (

    select
        {{ trim_protheus('x5_chave') }}   as cod_forma_pagamento,
        {{ trim_protheus('x5_descri') }}  as descricao,
        _carregado_em
    from {{ source('bronze', 'sx5010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('x5_tabela') }} = '58'

),

dedup as (

    select distinct on (cod_forma_pagamento)
        cod_forma_pagamento, descricao
    from formas
    order by cod_forma_pagamento, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_forma_pagamento']) }} as sk_forma_pagamento,
    cod_forma_pagamento,
    descricao
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Forma de pagamento não identificada'
