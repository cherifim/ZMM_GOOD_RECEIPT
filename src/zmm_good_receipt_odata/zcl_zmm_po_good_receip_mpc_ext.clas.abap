class ZCL_ZMM_PO_GOOD_RECEIP_MPC_EXT definition
  public
  inheriting from ZCL_ZMM_PO_GOOD_RECEIP_MPC
  create public .

public section.

  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZMM_PO_GOOD_RECEIP_MPC_EXT IMPLEMENTATION.


METHOD define.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_MPC_EXTCM001
*______________________________________________________________________________________*
* Date of creation: 31.03.2023 14:01:07  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Définir/Redéfinir certaines METADATA
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  super->define( ).

*  TRY.
*
*      DATA(lo_entity_type) = model->get_entity_type( 'PurchaseOrderItem').
*
*      DATA(lo_property) = lo_entity_type->get_property( iv_property_name = 'BatchNumber' ).
*
*      DATA(lo_annotation) = lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( iv_annotation_namespace =  /iwbep/if_mgw_med_odata_types=>gc_sap_namespace ).
*      lo_annotation->add( iv_key      = 'editable'
*                          iv_value    = 'true' ).
*
*      lo_annotation = lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( iv_annotation_namespace =  /iwbep/if_mgw_med_odata_types=>gc_sap_namespace ).
*      lo_annotation->add( iv_key      = 'contextEditable'
*                          iv_value    = 'true' ).
*
*    CATCH /iwbep/cx_mgw_med_exception.
*
*  ENDTRY.

ENDMETHOD.
ENDCLASS.
