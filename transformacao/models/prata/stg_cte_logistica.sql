/*
  CT-e (documento de frete), lado logistico (GW3010). Grao:
  recno_origem. Replica sqlCteLogistica (fFretes.m).
*/

select
    {{ trim_protheus('gw3_nrdf') }}    as numero_cte,
    {{ trim_protheus('gw3_serdf') }}   as serie_cte,
    {{ trim_protheus('gw3_emisdf') }}  as cod_transportador,
    {{ data_protheus('gw3_dtemis') }}  as dt_emissao,
    gw3_vldf                            as valor,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'gw3010') }}
where d_e_l_e_t_ <> '*'
