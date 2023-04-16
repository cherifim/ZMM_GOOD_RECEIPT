class ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXT definition
  public
  inheriting from ZCL_ZMM_PO_GOOD_RECEIP_DPC
  create public .

public section.

  types:
    BEGIN OF tys_purchase_order,
        data    TYPE zmm_gr_s_po_header_odata,
        request TYPE /iwbep/if_mgw_appl_types=>ty_s_changeset_request,
      END OF tys_purchase_order .
  types:
    tyt_purchase_orders TYPE STANDARD TABLE OF tys_purchase_order WITH DEFAULT KEY .

  types:
    BEGIN OF tys_purchase_order_item,
        data    TYPE zmm_gr_s_po_item_odata,
        request TYPE /iwbep/if_mgw_appl_types=>ty_s_changeset_request,
      END OF tys_purchase_order_item .
  types:
    tyt_purchase_order_items TYPE STANDARD TABLE OF tys_purchase_order_item WITH DEFAULT KEY .

  types:
    BEGIN OF tys_file_upload,
        data    TYPE zmm_gr_s_file_upload,
        request TYPE /iwbep/if_mgw_appl_types=>ty_s_changeset_request,
      END OF tys_file_upload .
  types:
    tyt_file_uploads TYPE STANDARD TABLE OF tys_file_upload WITH DEFAULT KEY .


  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_BEGIN
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_END
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_PROCESS
    redefinition .
protected section.

  methods GET_ENTITY_KEY
    returning
      value(ENTITY_KEY) type STRING .
  methods GET_ENTITY_KEY_FROM_CONTEXT
    importing
      !IO_REQUEST_CONTEXT type ref to /IWBEP/CL_MGW_REQUEST
    returning
      value(ENTITY_KEY) type STRING .
  methods GET_ENTITY_PROPERTIES
    importing
      !KEY_CONVERTER type ref to /IWBEP/CL_MGW_REQ_KEY_CONVERT optional
    returning
      value(PROPERTIES) type /IWBEP/IF_MGW_ODATA_FW_PROP=>TY_T_MGW_ODATA_PROPERTIES .
  methods ADD_MESSAGES_FROM_BAPI
    importing
      !IT_BAPI_MESSAGES type BAPIRET2_T
      !IV_ERROR_CATEGORY type /IWBEP/IF_MESSAGE_CONTAINER=>TY_ERROR_CATEGORY default /IWBEP/IF_MESSAGE_CONTAINER=>GCS_ERROR_CATEGORY-PROCESSING
      !IV_ENTITY_TYPE type STRING optional
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR optional
      !IV_ADD_TO_RESPONSE_HEADER type /IWBEP/SUP_MC_ADD_TO_RESPONSE default ABAP_TRUE
      !IV_IS_LEADING_MESSAGE type BOOLEAN default ABAP_FALSE
      !IO_MESSAGE_CONTAINER type ref to /IWBEP/IF_MESSAGE_CONTAINER
      !IO_REQUEST_CONTEXT type ref to /IWBEP/CL_MGW_REQUEST optional
      !IV_TRANSIENT type BOOLEAN default ABAP_FALSE .
  methods RAISE_BUSI_EXCEPTION_FROM_BAPI
    importing
      !IT_BAPI_MESSAGES type BAPIRET2_T
      !IV_ERROR_CATEGORY type /IWBEP/IF_MESSAGE_CONTAINER=>TY_ERROR_CATEGORY default /IWBEP/IF_MESSAGE_CONTAINER=>GCS_ERROR_CATEGORY-PROCESSING
      !IV_ENTITY_TYPE type STRING optional
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR optional
      !IV_ADD_TO_RESPONSE_HEADER type /IWBEP/SUP_MC_ADD_TO_RESPONSE default ABAP_TRUE
      !IV_IS_LEADING_MESSAGE type BOOLEAN default ABAP_TRUE
      !IO_REQUEST_CONTEXT type ref to /IWBEP/CL_MGW_REQUEST optional
      !IO_MESSAGE_CONTAINER type ref to /IWBEP/IF_MESSAGE_CONTAINER optional
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION .
  methods APPLY_SORTERS
    importing
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IO_KEY_CONVERTER type ref to /IWBEP/CL_MGW_REQ_KEY_CONVERT optional
      !IV_AUTO_CONVERT type BOOLEAN default ABAP_TRUE
    changing
      !ET_ENTITYSET type TABLE .
  methods PROCESS_MIGO_CHANGESET
    importing
      !IT_PURCHASE_ORDER_HEADERS type TYT_PURCHASE_ORDERS
      !IT_PURCHASE_ORDER_ITEMS type TYT_PURCHASE_ORDER_ITEMS
      !IT_FILE_UPLOADS type TYT_FILE_UPLOADS
    returning
      value(RT_CHANGESET_RESPONSE) type /IWBEP/IF_MGW_APPL_TYPES=>TY_T_CHANGESET_RESPONSE
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION .

  methods BATCHSHSET_GET_ENTITYSET
    redefinition .
  methods DUMMYFORSMARTFIE_GET_ENTITY
    redefinition .
  methods DUMMYFORSMARTFIE_UPDATE_ENTITY
    redefinition .
  methods FILEUPLOADSET_GET_ENTITYSET
    redefinition .
  methods PLANTSHSET_GET_ENTITYSET
    redefinition .
  methods PURCHASEORDERITE_GET_ENTITY
    redefinition .
  methods PURCHASEORDERITE_GET_ENTITYSET
    redefinition .
  methods PURCHASEORDERITE_UPDATE_ENTITY
    redefinition .
  methods PURCHASEORDERPER_GET_ENTITYSET
    redefinition .
  methods PURCHASEORDERSET_GET_ENTITY
    redefinition .
  methods PURCHASEORDERSET_UPDATE_ENTITY
    redefinition .
  methods STORAGELOCATIONS_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXT IMPLEMENTATION.


METHOD /iwbep/if_mgw_appl_srv_runtime~changeset_begin.

  SET UPDATE TASK LOCAL.
  cv_defer_mode = abap_true.

ENDMETHOD.


METHOD /iwbep/if_mgw_appl_srv_runtime~changeset_end.
  COMMIT WORK AND WAIT.
ENDMETHOD.


METHOD /iwbep/if_mgw_appl_srv_runtime~changeset_process.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00G
*______________________________________________________________________________________*
* Date of creation: 28.03.2023 20:45:04  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Exécution groupée de l'entrée de marchandises (Headers + Items)
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lo_request_context TYPE REF TO /iwbep/cl_mgw_request.
  DATA: lt_purchase_order_data TYPE tyt_purchase_orders.
  DATA: lt_purchase_order_item_data TYPE tyt_purchase_order_items.
  DATA: lt_file_upload_data TYPE tyt_file_uploads.
  DATA: lr_data_ref TYPE REF TO data.
  DATA: ls_changeset_response TYPE /iwbep/if_mgw_appl_types=>ty_s_changeset_response.

  LOOP AT it_changeset_request[] ASSIGNING FIELD-SYMBOL(<changeset_req>).

    lo_request_context ?= <changeset_req>-request_context.

    IF <changeset_req>-operation_type = 'PE' OR "MERGE
       <changeset_req>-operation_type = 'UE'. "UPDATE

      IF <changeset_req>-operation_type = 'PE'. "MERGE
        "Calculate merged data (modified data from UI5 and current data in SAP)
        me->/iwbep/if_mgw_appl_srv_runtime~patch_entity(
          EXPORTING
            iv_entity_name               = lo_request_context->get_request_details( )-source_entity
            iv_entity_set_name           = lo_request_context->get_request_details( )-source_entity_set
            iv_source_name               = lo_request_context->get_request_details( )-source_entity
            io_data_provider             = <changeset_req>-entry_provider
            it_key_tab                   = lo_request_context->get_request_details( )-key_tab[]
            it_navigation_path           = lo_request_context->get_request_details( )-navigation_path
            io_tech_request_context      = lo_request_context
          IMPORTING
            er_entity                    = lr_data_ref ).

        ASSIGN lr_data_ref->* TO FIELD-SYMBOL(<data>).
      ENDIF.


      CASE lo_request_context->get_request_details( )-source_entity.

        WHEN 'PurchaseOrder'.
          APPEND INITIAL LINE TO lt_purchase_order_data[] ASSIGNING FIELD-SYMBOL(<purchase_order_data>). "Collect PurchaseOrder entities
          IF <changeset_req>-operation_type = 'PE'. "MERGE
            <purchase_order_data>-data = <data>.
          ELSE. "UPDATE
            <changeset_req>-entry_provider->read_entry_data( IMPORTING es_data = <purchase_order_data>-data ).
          ENDIF.
          <purchase_order_data>-request = <changeset_req>.

        WHEN 'PurchaseOrderItem'.
          APPEND INITIAL LINE TO lt_purchase_order_item_data[] ASSIGNING FIELD-SYMBOL(<purchase_order_item_data>). "Collect PurchaseOrderItem entities
          IF <changeset_req>-operation_type = 'PE'. "MERGE
            <purchase_order_item_data>-data = <data>.
          ELSE. "UPDATE
            <changeset_req>-entry_provider->read_entry_data( IMPORTING es_data = <purchase_order_item_data>-data ).
          ENDIF.
          <purchase_order_item_data>-request = <changeset_req>.

        WHEN OTHERS. "Else execute the corresponding UPDATE_ENTITY method
          me->/iwbep/if_mgw_appl_srv_runtime~update_entity(
            EXPORTING
              iv_entity_name               = lo_request_context->get_request_details( )-source_entity
              iv_entity_set_name           = lo_request_context->get_request_details( )-source_entity_set
              iv_source_name               = lo_request_context->get_request_details( )-source_entity
              io_data_provider             = <changeset_req>-entry_provider
              it_key_tab                   = lo_request_context->get_request_details( )-key_tab[]
              it_navigation_path           = lo_request_context->get_request_details( )-navigation_path
              io_tech_request_context      = lo_request_context
            IMPORTING
              er_entity                    = lr_data_ref ).

          ASSIGN lr_data_ref->* TO <data>.

          CLEAR: ls_changeset_response.
          ls_changeset_response-operation_no = <changeset_req>-operation_no.

          copy_data_to_ref( EXPORTING is_data = <data>
                            CHANGING cr_data = ls_changeset_response-entity_data ).

          APPEND ls_changeset_response TO ct_changeset_response[].

      ENDCASE.

    ENDIF.

    IF <changeset_req>-operation_type = 'CE'. "CREATE ENTITY
      CASE lo_request_context->get_request_details( )-source_entity.
        WHEN 'FileUpload'.
          APPEND INITIAL LINE TO lt_file_upload_data[] ASSIGNING FIELD-SYMBOL(<file_upload_data>). "Collect FileUpload entities
          <changeset_req>-entry_provider->read_entry_data( IMPORTING es_data = <file_upload_data>-data ).
          <file_upload_data>-request = <changeset_req>.
        WHEN OTHERS.
      ENDCASE.
    ENDIF.

  ENDLOOP.

  "Execute the MIGO for the data set (Purchase Orders + Items + FileUpload)
  SORT lt_purchase_order_data[] BY data-purchase_order_number ASCENDING.
  SORT lt_purchase_order_item_data[] BY data-purchase_order_number ASCENDING data-item_number ASCENDING.
  DATA(lt_changeset_response) = me->process_migo_changeset( it_purchase_order_headers = lt_purchase_order_data[]
                                                            it_purchase_order_items   = lt_purchase_order_item_data[]
                                                            it_file_uploads           = lt_file_upload_data[] ).
  APPEND LINES OF lt_changeset_response[] TO ct_changeset_response[].

ENDMETHOD.


METHOD add_messages_from_bapi.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ADD_MESSAGES_FROM_BAPI
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:01:35  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Ajoute des messages à partie des messages de BAPI en calculant le Target pour le champ
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lv_message_target TYPE string.
  DATA: lo_key_converter TYPE REF TO /iwbep/cl_mgw_req_key_convert.

  IF io_request_context IS BOUND.
    lo_key_converter ?= io_request_context->get_request_details( )-technical_request-key_converter.
    DATA(lv_entity_set) = io_request_context->get_request_details( )-target_entity_set.
  ENDIF.

  DATA(lt_entity_properties) = me->get_entity_properties( lo_key_converter ).

  LOOP AT it_bapi_messages[] ASSIGNING FIELD-SYMBOL(<bapi_message>).
    "Calculate the target if Field property is filled
    CLEAR lv_message_target.
    DATA(lv_field) = to_upper( <bapi_message>-field ).
    ASSIGN lt_entity_properties[ technical_name = lv_field ] TO FIELD-SYMBOL(<entity_property>). "Get the oData property corresponding to the ABAP technical field
    IF sy-subrc = 0.
      lv_message_target = <entity_property>-name.
    ENDIF.

    "Absolute path if context provided
    IF io_request_context IS BOUND.
      DATA(lv_entity_key) = me->get_entity_key_from_context( io_request_context ).
      lv_message_target = lv_entity_key && '/' && lv_message_target.
    ENDIF.

    IF iv_transient = abap_true.
      lv_message_target = '/#TRANSIENT#' && lv_message_target.   "Same effect as setting parameter iv_is_transition_message to ABAP_TRUE in more recent versions
    ENDIF.

    DATA(lv_is_leading_message) = iv_is_leading_message.
    "By default, first message of container is the leading message
    IF iv_is_leading_message IS NOT SUPPLIED AND io_message_container->get_messages( ) IS INITIAL.
      lv_is_leading_message = abap_true.
    ENDIF.

    io_message_container->add_message(
        iv_msg_type               = <bapi_message>-type
        iv_msg_id                 = <bapi_message>-id
        iv_msg_number             = <bapi_message>-number
        iv_msg_text               = <bapi_message>-message
        iv_msg_v1                 = <bapi_message>-message_v1
        iv_msg_v2                 = <bapi_message>-message_v2
        iv_msg_v3                 = <bapi_message>-message_v3
        iv_msg_v4                 = <bapi_message>-message_v4
        iv_is_leading_message     = lv_is_leading_message
        iv_add_to_response_header = iv_add_to_response_header
        iv_entity_type            = iv_entity_type
        it_key_tab                = it_key_tab[]
        iv_error_category         = iv_error_category
        iv_message_target         = lv_message_target
    ).
  ENDLOOP.

ENDMETHOD.


METHOD apply_sorters.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCP
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:10:35  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Applique les tris sur les entités
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*


  " **** Apply sorters ****
  DATA(lt_order) = it_order[].

  "Replace names by technical names
  IF iv_auto_convert = abap_true.
    DATA(lt_entity_properties) = me->get_entity_properties( key_converter = io_key_converter ).
    LOOP AT lt_order[] ASSIGNING FIELD-SYMBOL(<order>).
      ASSIGN lt_entity_properties[ name = <order>-property ] TO FIELD-SYMBOL(<property>).
      CHECK sy-subrc = 0.
      <order>-property = <property>-technical_name.
    ENDLOOP.
  ENDIF.

  "Applique les tris
  CALL METHOD /iwbep/cl_mgw_data_util=>orderby
    EXPORTING
      it_order = lt_order[]
    CHANGING
      ct_data  = et_entityset[].


ENDMETHOD.


METHOD batchshset_get_entityset.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00A
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 22:08:34  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Retourne la liste des entités BatchSHSet selon les filtres
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*


  LOOP AT it_filter_select_options[] ASSIGNING FIELD-SYMBOL(<filter>).
    CASE <filter>-property.
      WHEN 'MaterialNumber'.
        DATA(lt_select_material_number) = <filter>-select_options[].
      WHEN 'BatchNumber'.
        DATA(lt_select_batch_number) = <filter>-select_options[].
      WHEN 'VendorAccountNumber'.
        DATA(lt_select_vendor_accnt_number) = <filter>-select_options[].
      WHEN 'VendorBatchNumber'.
        DATA(lt_select_vendor_batch_number) = <filter>-select_options[].
    ENDCASE.
  ENDLOOP.

  "Inbound conversion Material number  (convert 123 into 000000000000000123)
  zcl_good_receipt_odata_helper=>sel_opt_conversion_matn1_input( CHANGING it_select_options = lt_select_material_number[] ).


  "Sélection de données selon filtres
  et_entityset[] = zcl_good_receipt_odata_helper=>get_batches_sh_data(
      it_sel_opt_material_number     = lt_select_material_number[]        " Filtre sur Article
      it_sel_opt_batch_number        = lt_select_batch_number[]           " Filtre sur Lot
      it_sel_opt_vendor_accnt_number = lt_select_vendor_accnt_number[]    " Filtre sur Fournisseur
      it_sel_opt_vendor_batch_number = lt_select_vendor_batch_number[]    " Filtre sur Lot fournisseur
  ).

  "Applique les tris
  me->apply_sorters( EXPORTING it_order    = it_order[]
                     CHANGING et_entityset = et_entityset[] ).


ENDMETHOD.


METHOD dummyforsmartfie_get_entity.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00D
*______________________________________________________________________________________*
* Date of creation: 27.03.2023 16:09:56  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :   Get a dummy entity for PO Number selection on UI5 SmartField
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  ASSIGN it_key_tab[ name = 'ID' ] TO FIELD-SYMBOL(<key>).
  er_entity-id = <key>-value.

ENDMETHOD.


METHOD dummyforsmartfie_update_entity.
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ). "Do nothing
ENDMETHOD.


METHOD fileuploadset_get_entityset.

ENDMETHOD.


METHOD get_entity_key.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: GET_ENTITI_KEY
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 16:54:17  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :
*                 Retourne la clé de l'entité en cours (passé via URL)
*                 Cette méthode peut être utilisée pour calculer les Target des exception messages
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*


  DATA(lv_target_entity_set_name) = me->mr_request_details->target_entity_set. "ex: PurchaseOrderSet

  DATA(lt_request_header) = me->mr_request_details->technical_request-request_header[].
  ASSIGN lt_request_header[ name = '~request_uri' ] TO FIELD-SYMBOL(<uri>). "ex: /sap/opu/odata/SAP/ZMM_PO_GOOD_RECEIPT/PurchaseOrderSet(PurchaseOrderNumber='0000000279')
  IF sy-subrc = 0.
    SPLIT <uri>-value AT lv_target_entity_set_name INTO DATA(lv_str1) entity_key. "ex: (PurchaseOrderNumber='0000000279')
    SPLIT entity_key AT '?' INTO entity_key lv_str1. "Enlève les paramètres URL après ? si ils existent
    entity_key = '/' && lv_target_entity_set_name && entity_key. "ex: /PurchaseOrderSet(PurchaseOrderNumber='0000000279')
  ENDIF.

ENDMETHOD.


METHOD get_entity_key_from_context.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: GET_ENTITI_KEY
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 16:54:17  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :
*                 Retourne la clé de l'entité d'une requête donnée
*                 Cette méthode peut être utilisée pour calculer les Target des exception messages
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA(lv_target_entity_set_name) = io_request_context->get_request_details( )-target_entity_set. "ex: PurchaseOrderSet

  DATA(lt_request_header) = io_request_context->get_request_details( )-technical_request-request_header[].
  ASSIGN lt_request_header[ name = '~request_uri' ] TO FIELD-SYMBOL(<uri>). "ex: /sap/opu/odata/SAP/ZMM_PO_GOOD_RECEIPT/PurchaseOrderSet(PurchaseOrderNumber='0000000279')
  IF sy-subrc = 0.
    SPLIT <uri>-value AT lv_target_entity_set_name INTO DATA(lv_str1) entity_key. "ex: (PurchaseOrderNumber='0000000279')
    SPLIT entity_key AT '?' INTO entity_key lv_str1. "Enlève les paramètres URL après ? si ils existent
    entity_key = '/' && lv_target_entity_set_name && entity_key. "ex: /PurchaseOrderSet(PurchaseOrderNumber='0000000279')
  ENDIF.

ENDMETHOD.


METHOD get_entity_properties.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: GET_ENTITY_PROPERTIES
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 16:58:02  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Retourne les propriétés de l'entité en cours
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lo_converter TYPE REF TO /iwbep/cl_mgw_req_key_convert.

  IF me->mr_request_details IS BOUND. "Par défaut on utilise le converteur en cours
    lo_converter ?= me->mr_request_details->technical_request-key_converter.
  ENDIF.

  IF key_converter IS BOUND.
    lo_converter = key_converter.
  ENDIF.

  CHECK lo_converter IS BOUND.

  DATA(lo_entity_type) = lo_converter->/iwbep/if_mgw_req_key_convert~get_entity_type( ).
  TRY .
      properties[] = lo_entity_type->get_properties( ).
    CATCH /iwbep/cx_mgw_med_exception.
  ENDTRY.

ENDMETHOD.


METHOD plantshset_get_entityset.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00B
*______________________________________________________________________________________*
* Date of creation: 25.03.2023 10:21:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Retourne la liste des entités PlantSHSet selon les filtres
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  LOOP AT it_filter_select_options[] ASSIGNING FIELD-SYMBOL(<filter>).
    CASE <filter>-property.
      WHEN 'Plant'.
        DATA(lt_select_plant) = <filter>-select_options[].
      WHEN 'Name'.
        DATA(lt_select_name) = <filter>-select_options[].
        "Convert to UPPER CASE
        LOOP AT lt_select_name[] ASSIGNING FIELD-SYMBOL(<select_name>).
          <select_name>-low = to_upper( <select_name>-low ).
          <select_name>-high = to_upper( <select_name>-high ).
        ENDLOOP.
    ENDCASE.
  ENDLOOP.

  "Sélection de données selon filtres
  et_entityset[] = zcl_good_receipt_odata_helper=>get_plants_sh_data(
                     it_sel_opt_plant = lt_select_plant[]   "Filtre sur Division
                     it_sel_opt_name  = lt_select_name[]   "Filtre sur Nom Division
                 ).


  "Applique les tris
  me->apply_sorters( EXPORTING it_order    = it_order[]
                     CHANGING et_entityset = et_entityset[] ).


ENDMETHOD.


METHOD process_migo_changeset.

*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00K
*______________________________________________________________________________________*
* Date of creation: 29.03.2023 16:21:43  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Valider les données d'entrée et exécuter l'entrée de marchandise
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lo_request_main_context TYPE REF TO /iwbep/cl_mgw_request.
  DATA: lo_request_context TYPE REF TO /iwbep/cl_mgw_request.
  DATA: ls_response LIKE LINE OF rt_changeset_response[].
  DATA: lo_main_msg_container TYPE REF TO /iwbep/if_message_container.
  DATA: lt_po_header_input TYPE zcl_good_receipt_helper=>tyt_po_header_input.

  "***********************************
  "*  Générer les données des réponses
  "***********************************
  " On part du principe que les données de sortie = données d'entrée car les données
  " vont être rafraichies dans SAPUI5 après exécution de l'entrée de marchandise avec
  " relecture des données du modèle
  LOOP AT it_purchase_order_headers[] ASSIGNING FIELD-SYMBOL(<po_header>).

    IF lo_main_msg_container IS NOT BOUND.
      lo_main_msg_container = <po_header>-request-msg_container.
    ENDIF.
    IF lo_request_main_context IS NOT BOUND.
      lo_request_main_context ?= <po_header>-request-request_context.
    ENDIF.

    CLEAR ls_response.
    ls_response-operation_no = <po_header>-request-operation_no.
    copy_data_to_ref( EXPORTING is_data = <po_header>-data
                      CHANGING  cr_data = ls_response-entity_data ).
    INSERT ls_response INTO TABLE rt_changeset_response[].

    "Vérifier que pour une commande d'achat au moins un poste a été renseigné
    IF NOT line_exists( it_purchase_order_items[ data-purchase_order_number = <po_header>-data-purchase_order_number
                                                 data-update = abap_true ] ).
      "Pas de requête trouvée avec un poste de la commande d'achat
      me->add_messages_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                id = 'ZMM_GOOD_RECEIPT'
                                                                number = 004 "Aucune donnée de poste renseignée pour la commande d'achat &1
                                                                message_v1 = <po_header>-data-purchase_order_number
                                                                field = 'PURCHASE_ORDER_NUMBER') )
                                  io_message_container = lo_main_msg_container
                                  io_request_context = lo_request_main_context ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_main_msg_container.
    ENDIF.

  ENDLOOP.

  LOOP AT it_purchase_order_items[] ASSIGNING FIELD-SYMBOL(<po_item>).

    IF lo_main_msg_container IS NOT BOUND.
      lo_main_msg_container = <po_item>-request-msg_container.
    ENDIF.
    lo_request_context ?= <po_item>-request-request_context.

    CLEAR ls_response.
    ls_response-operation_no = <po_item>-request-operation_no.
    copy_data_to_ref( EXPORTING is_data = <po_item>-data
                      CHANGING  cr_data = ls_response-entity_data ).
    INSERT ls_response INTO TABLE rt_changeset_response[].

    "Vérifier que l'entête de la commande d'achat est présent dans les requêtes reçues (seulement si le poste a été désigné comme modifié)
    CHECK <po_item>-data-update = abap_true.
    IF NOT line_exists( it_purchase_order_headers[ data-purchase_order_number = <po_item>-data-purchase_order_number ] ).
      "Pas de requête trouvée pour l'entête de la commande d'achat
      me->add_messages_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                id = 'ZMM_GOOD_RECEIPT'
                                                                number = 005 "Aucune donnée d'entête reçue pour la commande d'achat &1
                                                                message_v1 = <po_item>-data-purchase_order_number
                                                                field = 'PURCHASE_ORDER_NUMBER') )
                                  io_message_container = lo_main_msg_container
                                  io_request_context = lo_request_context ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_main_msg_container.
    ENDIF.

  ENDLOOP.

  LOOP AT it_file_uploads[] ASSIGNING FIELD-SYMBOL(<file_upload>).
    CLEAR ls_response.
    ls_response-operation_no = <file_upload>-request-operation_no.
    INSERT ls_response INTO TABLE rt_changeset_response[].
  ENDLOOP.

  "**************************************
  "     Validation de données d'entrée
  "**************************************
  LOOP AT it_purchase_order_headers[] ASSIGNING <po_header>.

    IF lo_main_msg_container IS NOT BOUND.
      lo_main_msg_container = <po_header>-request-msg_container.
    ENDIF.

    lo_request_context ?= <po_header>-request-request_context.

    "Date comptable obligatoire
    IF <po_header>-data-document_posting_date IS INITIAL.

      me->add_messages_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                id = 'ZMM_GOOD_RECEIPT'
                                                                number = 002 "Date comptable obligatoire
                                                                field = 'DOCUMENT_POSTING_DATE') )
                                  io_message_container = lo_main_msg_container
                                  io_request_context = lo_request_context ).

      DATA(lv_error_detected) = abap_true.

    ENDIF.

    APPEND VALUE #( purchase_order_number = <po_header>-data-purchase_order_number
                    document_posting_date = <po_header>-data-document_posting_date
                    document_header_text = <po_header>-data-document_header_text
                    delivery_note = <po_header>-data-delivery_note ) TO lt_po_header_input[] ASSIGNING FIELD-SYMBOL(<po_input>).

    LOOP AT it_purchase_order_items[] ASSIGNING <po_item>
      WHERE data-purchase_order_number = <po_header>-data-purchase_order_number AND
            data-update = abap_true.

      CLEAR ls_response.
      ls_response-operation_no = <po_item>-request-operation_no.
      copy_data_to_ref( EXPORTING is_data = <po_item>-data
                        CHANGING  cr_data = ls_response-entity_data ).
      INSERT ls_response INTO TABLE rt_changeset_response[].

      lo_request_context ?= <po_item>-request-request_context.

      IF <po_item>-data-receipt_quantity = 0.
        lv_error_detected = abap_true.
        me->add_messages_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                  id = 'ZMM_GOOD_RECEIPT'
                                                                  number = 003 "La quantité à la réception ne peut pas être nulle
                                                                  field = 'RECEIPT_QUANTITY' ) )
                                    io_message_container = lo_main_msg_container
                                    io_request_context = lo_request_context ).
      ENDIF.

      APPEND VALUE #( item_number           = <po_item>-data-item_number
                      purchase_order_unit   = <po_item>-data-purchase_order_unit
                      receipt_quantity      = <po_item>-data-receipt_quantity ) TO <po_input>-items[].

    ENDLOOP.

    "Incorporer les fichiers lié à la commande d'achat
    LOOP AT it_file_uploads[] ASSIGNING <file_upload> WHERE data-purchase_order_number = <po_header>-data-purchase_order_number.
      APPEND VALUE #( file_name    = <file_upload>-data-file_name
                      file_content = <file_upload>-data-file_content
                      mime_type    = <file_upload>-data-mime_type
                      is_url       = <file_upload>-data-is_url
                      url          = <file_upload>-data-url ) TO <po_input>-files[].
    ENDLOOP.

  ENDLOOP.

  " Erreurs de validation détectées --> lever les exceptions et arrêter le traitement
  IF lv_error_detected = abap_true.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_main_msg_container.
  ENDIF.

  "**************************************
  "         Appel de la MIGO
  "**************************************
  LOOP AT lt_po_header_input[] ASSIGNING <po_input>.
    DATA(lt_return) = zcl_good_receipt_helper=>perform_po_good_receipt( is_po_input = <po_input> ).

    LOOP AT lt_return[] ASSIGNING FIELD-SYMBOL(<return>).
      <return>-field = 'PURCHASE_ORDER_NUMBER'.
    ENDLOOP.

    IF line_exists( lt_return[ TYPE = 'E' ] ).
      DATA(lv_transient) = abap_false. "Non-Persistent message
    ELSE.
      lv_transient = abap_true. "Persistent message
    ENDIF.

    me->add_messages_from_bapi( it_bapi_messages = lt_return[]
                                io_message_container = lo_main_msg_container
                                io_request_context  = lo_request_main_context
                                iv_transient = lv_transient ).

    IF line_exists( lt_return[ type = 'E' ] ). "At least one error occured
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_main_msg_container.
    ENDIF.
  ENDLOOP.


ENDMETHOD.


METHOD purchaseorderite_get_entity.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM008
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:39:31  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Retourne une entité PurchaseOrderItemSet selon la clé
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lv_purchase_order_number TYPE ebeln.
  DATA: lv_purchase_order_item TYPE ebelp.

  IF it_navigation_path[] IS NOT INITIAL. "Accès via propriétés de navigation
    IF iv_source_name = 'PurchaseOrder' AND line_exists( it_navigation_path[ nav_prop = 'Items' ]  ). "Cas de navigation à partir d'une commande d'achat
      "Récupérer le numéro de commande d'achat à partir duquel l'assictaion a été invoquée
      ASSIGN it_key_tab[ name = 'PurchaseOrderNumber' ] TO FIELD-SYMBOL(<key>).
      IF sy-subrc <> 0.
        me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                          id = 'ZMM_GOOD_RECEIPT'
                                                                          number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                          message_v1 = 'PurchaseOrder' ) ) ).
      ENDIF.

      lv_purchase_order_number = <key>-value.

      "Récupérer la clé du poste de commande d'achat
      ASSIGN it_navigation_path[ nav_prop = 'Items' ]-key_tab[ name = 'PurchaseOrderNumber' ] TO <key>.
      IF sy-subrc <> 0.
        me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                          id = 'ZMM_GOOD_RECEIPT'
                                                                          number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                          message_v1 = 'PurchaseOrderItem' ) ) ).
      ENDIF.

      IF lv_purchase_order_number <> <key>-value. "Numéro de commande d'achat du poste différent du numéro de commande d'achat source
        me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                          id = 'ZMM_GOOD_RECEIPT'
                                                                          number = 006 "OData: Numéro de commande d'achat &1 différent de la source &2
                                                                          message_v1 = <key>-value
                                                                          message_v2 = lv_purchase_order_number ) ) ).
      ENDIF.

      ASSIGN it_navigation_path[ nav_prop = 'Items' ]-key_tab[ name = 'ItemNumber' ] TO <key>.
      IF sy-subrc <> 0.
        me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                          id = 'ZMM_GOOD_RECEIPT'
                                                                          number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                          message_v1 = 'PurchaseOrderItem' ) ) ).
      ENDIF.

      lv_purchase_order_item = <key>-value.

    ENDIF.

  ELSE. "Accès direct

    ASSIGN it_key_tab[ name = 'PurchaseOrderNumber' ] TO <key>.
    IF sy-subrc <> 0.
      me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                        id = 'ZMM_GOOD_RECEIPT'
                                                                        number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                        message_v1 = 'PurchaseOrderItem' ) ) ).
    ENDIF.

    lv_purchase_order_number = <key>-value.

    ASSIGN it_key_tab[ name = 'ItemNumber' ] TO <key>.
    IF sy-subrc <> 0.
      me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                        id = 'ZMM_GOOD_RECEIPT'
                                                                        number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                        message_v1 = 'PurchaseOrderItem' ) ) ).
    ENDIF.

    lv_purchase_order_item = <key>-value.
  ENDIF.


  "Select data and populate structure ER_ENTITY
  DATA(lt_entityset) = zcl_good_receipt_odata_helper=>get_purchase_order_items_data( po_number               = lv_purchase_order_number
                                                                                     it_sel_opt_item_numbers = VALUE #( ( sign = 'I'
                                                                                                                          option = 'EQ'
                                                                                                                          low = lv_purchase_order_item  ) ) ).
  IF lt_entityset[] IS NOT INITIAL.
    er_entity = lt_entityset[ 1 ].
  ENDIF.

ENDMETHOD.


METHOD purchaseorderite_get_entityset.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname:  PURCHASEORDERITE_GET_ENTITYSET
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:24:03  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Retourne les entités PurchaseOrderItem selon filtres
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lv_po_number TYPE ebeln.

  LOOP AT it_filter_select_options[] ASSIGNING FIELD-SYMBOL(<filter>).
    CASE <filter>-property.
      WHEN 'ItemNumber'.
        DATA(lt_select_po_item) = <filter>-select_options[].
      WHEN 'RequirementTrackingNumber'.
        DATA(lt_select_req_trck_num) = <filter>-select_options[].
    ENDCASE.
  ENDLOOP.

  IF it_navigation_path[] IS NOT INITIAL. "Accès via propriétés de navigation
    IF iv_source_name = 'PurchaseOrder' AND line_exists( it_navigation_path[ nav_prop = 'Items' ]  ). "Cas de navigation à partir d'une commande d'achat
      "Récupérer le numéro de commande d'achat à partir duquel l'assictaion a été invoquée
      ASSIGN it_key_tab[ name = 'PurchaseOrderNumber' ] TO FIELD-SYMBOL(<key_id_po_number>).
      IF sy-subrc <> 0.
        me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                          id = 'ZMM_GOOD_RECEIPT'
                                                                          number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                          message_v1 = 'PurchaseOrder' ) ) ).
      ENDIF.

      lv_po_number = <key_id_po_number>-value.

      et_entityset[] = zcl_good_receipt_odata_helper=>get_purchase_order_items_data( po_number               = lv_po_number
                                                                                     it_sel_opt_item_numbers = lt_select_po_item[]
                                                                                     it_sel_opt_req_trck_num = lt_select_req_trck_num[] ).

      "For order cannot get the converter out of the context in case of navigation from another source entity
      DATA(lt_order) = it_order[].
      LOOP AT lt_order[] ASSIGNING FIELD-SYMBOL(<order>).
        CASE <order>-property.
          WHEN 'PurchaseOrderNumber'. <order>-property = 'PURCHASE_ORDER_NUMBER'.
          WHEN 'ItemNumber'. <order>-property = 'ITEM_NUMBER'.
          WHEN 'Update'. <order>-property = 'UPDATE'.
          WHEN 'Designation'.<order>-property = 'DESIGNATION'.
          WHEN 'PurchaseOrderItemTxt'.<order>-property = 'PURCHASE_ORDER_ITEM_TXT'.
          WHEN 'Plant'.<order>-property = 'PLANT'.
          WHEN 'PlantName'.<order>-property = 'PLANT_NAME'.
          WHEN 'StorageLocation'.<order>-property = 'STORAGE_LOCATION'.
          WHEN 'StorageLocationDesc'.<order>-property = 'STORAGE_LOCATION_DESC'.
          WHEN 'MaterialNumber'.<order>-property = 'MATERIAL_NUMBER'.
          WHEN 'MaterialDesc'.<order>-property = 'MATERIAL_DESC'.
          WHEN 'CreatorUser'.<order>-property = 'CREATOR_USER'.
          WHEN 'CreatorName'.<order>-property = 'CREATOR_NAME'.
          WHEN 'BatchNumber'.<order>-property = 'BATCH_NUMBER'.
          WHEN 'PurchaseOrderQuantity'.<order>-property = 'PURCHASE_ORDER_QUANTITY'.
          WHEN 'PurchaseOrderUnit'.<order>-property = 'PURCHASE_ORDER_UNIT'.
          WHEN 'ReceiptQuantity'.<order>-property = 'RECEIPT_QUANTITY'.
          WHEN 'RemainingQuantity'.<order>-property = 'REMAINING_QUANTITY'.
          WHEN 'CostCenter'.<order>-property = 'COST_CENTER'.
          WHEN 'CostCenterName'.<order>-property = 'COST_CENTER_NAME'.
          WHEN 'CostCenterDesc'.<order>-property = 'COST_CENTER_DESC'.
          WHEN 'WbsElement'.<order>-property = 'WBS_ELEMENT'.
          WHEN 'WbsElementDesc'.<order>-property = 'WBS_ELEMENT_DESC'.
          WHEN 'RequirementTrackingNumber'.<order>-property = 'REQUIREMENT_TRACKING_NUMBER'.
          WHEN 'AddressName'.<order>-property = 'ADDRESS_NAME'.
          WHEN 'City'.<order>-property = 'CITY'.
          WHEN 'ZipCode'.<order>-property = 'ZIP_CODE'.
          WHEN 'Street'.<order>-property = 'STREET'.
          WHEN 'HouseNum'.<order>-property = 'HOUSE_NUM'.
          WHEN 'CountryCode'.<order>-property = 'COUNTRY_CODE'.
        ENDCASE.
      ENDLOOP.

      "Applique les tris
      me->apply_sorters( EXPORTING it_order = lt_order[]
                                   iv_auto_convert = abap_false
                         CHANGING et_entityset = et_entityset[] ).

    ENDIF.
  ENDIF.


ENDMETHOD.


METHOD purchaseorderite_update_entity.
  "Update not implemented - see CHANGESET_PROCESS
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).
ENDMETHOD.


METHOD purchaseorderper_get_entityset.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00E
*______________________________________________________________________________________*
* Date of creation: 28.03.2023 14:33:41  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Search Help on Purchase Orders using Vendor information
*                 THIS A COPY OF GENERATED GET_ENTITYSET METHOD FOR SEARCH HELP - SEE SUPER METHOD
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

*-------------------------------------------------------------
*  Data declaration
*-------------------------------------------------------------
  DATA lo_filter TYPE  REF TO /iwbep/if_mgw_req_filter.
  DATA lt_filter_select_options TYPE /iwbep/t_mgw_select_option.
  DATA lv_filter_str TYPE string.
  DATA lv_max_hits TYPE i.
  DATA ls_paging TYPE /iwbep/s_mgw_paging.
  DATA ls_converted_keys LIKE LINE OF et_entityset.
  DATA ls_message TYPE bapiret2.
  DATA lt_selopt TYPE ddshselops.
  DATA ls_selopt LIKE LINE OF lt_selopt.
  DATA ls_filter TYPE /iwbep/s_mgw_select_option.
  DATA ls_filter_range TYPE /iwbep/s_cod_select_option.
  DATA lr_lifnr LIKE RANGE OF ls_converted_keys-lifnr.
  DATA ls_lifnr LIKE LINE OF lr_lifnr.
  DATA lr_ekorg LIKE RANGE OF ls_converted_keys-ekorg.
  DATA ls_ekorg LIKE LINE OF lr_ekorg.
  DATA lr_ekgrp LIKE RANGE OF ls_converted_keys-ekgrp.
  DATA ls_ekgrp LIKE LINE OF lr_ekgrp.
  DATA lr_bedat LIKE RANGE OF ls_converted_keys-bedat.
  DATA ls_bedat LIKE LINE OF lr_bedat.
  DATA lr_bstyp LIKE RANGE OF ls_converted_keys-bstyp.
  DATA ls_bstyp LIKE LINE OF lr_bstyp.
  DATA lr_bsart LIKE RANGE OF ls_converted_keys-bsart.
  DATA ls_bsart LIKE LINE OF lr_bsart.
  DATA lr_ebeln LIKE RANGE OF ls_converted_keys-ebeln.
  DATA ls_ebeln LIKE LINE OF lr_ebeln.
  DATA lt_result_list TYPE /iwbep/if_sb_gendpc_shlp_data=>tt_result_list.
  DATA lv_next TYPE i VALUE 1.
  DATA ls_entityset LIKE LINE OF et_entityset.
  DATA ls_result_list_next LIKE LINE OF lt_result_list.
  DATA ls_result_list LIKE LINE OF lt_result_list.


*-------------------------------------------------------------
*  Map the runtime request to the Search Help select option - Only mapped attributes
*-------------------------------------------------------------
* Get all input information from the technical request context object
* Since DPC works with internal property names and runtime API interface holds external property names
* the process needs to get the all needed input information from the technical request context object
* Get filter or select option information
  lo_filter = io_tech_request_context->get_filter( ).
  lt_filter_select_options = lo_filter->get_filter_select_options( ).
  lv_filter_str = lo_filter->get_filter_string( ).

  IF iv_search_string IS NOT INITIAL.
    APPEND INITIAL LINE TO lt_filter_select_options[] ASSIGNING FIELD-SYMBOL(<select_option>).
    <select_option>-property = 'EBELN'.
    <select_option>-select_options = VALUE #( ( sign = 'I' option = 'CP' low = |{ iv_search_string }*| ) ).
  ENDIF.

* Check if the supplied filter is supported by standard gateway runtime process
  IF  lv_filter_str            IS NOT INITIAL
  AND lt_filter_select_options IS INITIAL.
    " If the string of the Filter System Query Option is not automatically converted into
    " filter option table (lt_filter_select_options), then the filtering combination is not supported
    " Log message in the application log
    me->/iwbep/if_sb_dpc_comm_services~log_message(
      EXPORTING
        iv_msg_type   = 'E'
        iv_msg_id     = '/IWBEP/MC_SB_DPC_ADM'
        iv_msg_number = 025 ).
    " Raise Exception
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
      EXPORTING
        textid = /iwbep/cx_mgw_tech_exception=>internal_error.
  ENDIF.

* Get key table information
  io_tech_request_context->get_converted_source_keys(
    IMPORTING
      es_key_values  = ls_converted_keys ).

  ls_paging-top = io_tech_request_context->get_top( ).
  ls_paging-skip = io_tech_request_context->get_skip( ).

  " Calculate the number of max hits to be fetched from the function module
  " The lv_max_hits value is a summary of the Top and Skip values
  IF ls_paging-top > 0.
    lv_max_hits = is_paging-top + is_paging-skip.
  ENDIF.

* Maps filter table lines to the Search Help select option table
  LOOP AT lt_filter_select_options INTO ls_filter.

    CASE ls_filter-property.
      WHEN 'LIFNR'.              " Equivalent to 'VendorAccountNumber' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_lifnr ).

        LOOP AT lr_lifnr INTO ls_lifnr.
          ls_selopt-high = ls_lifnr-high.
          ls_selopt-low = ls_lifnr-low.
          ls_selopt-option = ls_lifnr-option.
          ls_selopt-sign = ls_lifnr-sign.
          ls_selopt-shlpfield = 'LIFNR'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'EKORG'.              " Equivalent to 'PurchOrganization' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_ekorg ).

        LOOP AT lr_ekorg INTO ls_ekorg.
          ls_selopt-high = ls_ekorg-high.
          ls_selopt-low = ls_ekorg-low.
          ls_selopt-option = ls_ekorg-option.
          ls_selopt-sign = ls_ekorg-sign.
          ls_selopt-shlpfield = 'EKORG'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'EKGRP'.              " Equivalent to 'PurchGroup' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_ekgrp ).

        LOOP AT lr_ekgrp INTO ls_ekgrp.
          ls_selopt-high = ls_ekgrp-high.
          ls_selopt-low = ls_ekgrp-low.
          ls_selopt-option = ls_ekgrp-option.
          ls_selopt-sign = ls_ekgrp-sign.
          ls_selopt-shlpfield = 'EKGRP'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'BEDAT'.              " Equivalent to 'PurchDocDate' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_bedat ).

        LOOP AT lr_bedat INTO ls_bedat.
          ls_selopt-high = ls_bedat-high.
          ls_selopt-low = ls_bedat-low.
          ls_selopt-option = ls_bedat-option.
          ls_selopt-sign = ls_bedat-sign.
          ls_selopt-shlpfield = 'BEDAT'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'BSTYP'.              " Equivalent to 'PurchDocCategory' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_bstyp ).

        LOOP AT lr_bstyp INTO ls_bstyp.
          ls_selopt-high = ls_bstyp-high.
          ls_selopt-low = ls_bstyp-low.
          ls_selopt-option = ls_bstyp-option.
          ls_selopt-sign = ls_bstyp-sign.
          ls_selopt-shlpfield = 'BSTYP'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'BSART'.              " Equivalent to 'OrderType' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_bsart ).

        LOOP AT lr_bsart INTO ls_bsart.
          ls_selopt-high = ls_bsart-high.
          ls_selopt-low = ls_bsart-low.
          ls_selopt-option = ls_bsart-option.
          ls_selopt-sign = ls_bsart-sign.
          ls_selopt-shlpfield = 'BSART'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.
      WHEN 'EBELN'.              " Equivalent to 'PurchaseOrderNumber' property in the service
        lo_filter->convert_select_option(
          EXPORTING
            is_select_option = ls_filter
          IMPORTING
            et_select_option = lr_ebeln ).

        LOOP AT lr_ebeln INTO ls_ebeln.
          ls_selopt-high = ls_ebeln-high.
          ls_selopt-low = ls_ebeln-low.
          ls_selopt-option = ls_ebeln-option.
          ls_selopt-sign = ls_ebeln-sign.
          ls_selopt-shlpfield = 'EBELN'.
          ls_selopt-shlpname = 'MEKKL'.
          APPEND ls_selopt TO lt_selopt.
          CLEAR ls_selopt.
        ENDLOOP.

      WHEN OTHERS.
        " Log message in the application log
        me->/iwbep/if_sb_dpc_comm_services~log_message(
          EXPORTING
            iv_msg_type   = 'E'
            iv_msg_id     = '/IWBEP/MC_SB_DPC_ADM'
            iv_msg_number = 020
            iv_msg_v1     = ls_filter-property ).
        " Raise Exception
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid = /iwbep/cx_mgw_tech_exception=>internal_error.
    ENDCASE.
  ENDLOOP.

*-------------------------------------------------------------
*  Call to Search Help get values mechanism
*-------------------------------------------------------------
* Get search help values
  me->/iwbep/if_sb_gendpc_shlp_data~get_search_help_values(
    EXPORTING
      iv_shlp_name = 'MEKKL'
      iv_maxrows = lv_max_hits
      iv_sort = 'X'
      iv_call_shlt_exit = 'X'
      it_selopt = lt_selopt
    IMPORTING
      et_return_list = lt_result_list
      es_message = ls_message ).

*-------------------------------------------------------------
*  Map the Search Help returned results to the caller interface - Only mapped attributes
*-------------------------------------------------------------
  IF ls_message IS NOT INITIAL.
* Call RFC call exception handling
    me->/iwbep/if_sb_dpc_comm_services~rfc_save_log(
      EXPORTING
        is_return      = ls_message
        iv_entity_type = iv_entity_name
        it_key_tab     = it_key_tab ).
  ENDIF.

  CLEAR et_entityset.

  LOOP AT lt_result_list INTO ls_result_list
    WHERE record_number > ls_paging-skip.

    " Move SH results to GW request responce table
    lv_next = sy-tabix + 1. " next loop iteration
    CASE ls_result_list-field_name.
      WHEN 'BEDAT'.
        ls_entityset-bedat = ls_result_list-field_value.
      WHEN 'BSART'.
        ls_entityset-bsart = ls_result_list-field_value.
      WHEN 'BSTYP'.
        ls_entityset-bstyp = ls_result_list-field_value.
      WHEN 'EBELN'.
        ls_entityset-ebeln = ls_result_list-field_value.
      WHEN 'EKGRP'.
        ls_entityset-ekgrp = ls_result_list-field_value.
      WHEN 'EKORG'.
        ls_entityset-ekorg = ls_result_list-field_value.
      WHEN 'LIFNR'.
        ls_entityset-lifnr = ls_result_list-field_value.
    ENDCASE.

    " Check if the next line in the result list is a new record
    READ TABLE lt_result_list INTO ls_result_list_next INDEX lv_next.
    IF sy-subrc <> 0
    OR ls_result_list-record_number <> ls_result_list_next-record_number.
      " Save the collected SH result in the GW request table
      APPEND ls_entityset TO et_entityset.
      CLEAR: ls_result_list_next, ls_entityset.
    ENDIF.

  ENDLOOP.


ENDMETHOD.


METHOD purchaseorderset_get_entity.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM008
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:39:31  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Retourne une entité PurchaseOrderSet selon la clé
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lv_purchase_order_number TYPE ebeln.

  ASSIGN it_key_tab[ name = 'PurchaseOrderNumber' ] TO FIELD-SYMBOL(<key>).
  IF sy-subrc <> 0.
    me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                      id = 'ZMM_GOOD_RECEIPT'
                                                                      number = 1 "OData: Clé sur entité &1 manquante ou incorrecte
                                                                      message_v1 = 'PurchaseOrderSet' ) ) ).
  ENDIF.

  lv_purchase_order_number = <key>-value.

  "Sélection de données
  er_entity = zcl_good_receipt_odata_helper=>get_purchase_order_data( po_number = lv_purchase_order_number ).

  IF er_entity IS INITIAL.
    me->raise_busi_exception_from_bapi( it_bapi_messages = VALUE #( ( type = 'E'
                                                                      id = 'ZMM_GOOD_RECEIPT'
                                                                      number = 008" Commande d'achat &1 non trouvée
                                                                      message_v1 = lv_purchase_order_number ) ) ).
  ENDIF.


ENDMETHOD.


METHOD purchaseorderset_update_entity.
  "Update not implemented - see CHANGESET_PROCESS
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).
ENDMETHOD.


METHOD raise_busi_exception_from_bapi.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: RAISE_BUSI_EXCEPTION_FROM_BAPI
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 17:08:14  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Raise an exception from BAPI messages
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA(lo_message_container) = io_message_container.

  IF lo_message_container IS NOT BOUND. "Default = take the message container of the current context
    lo_message_container = mo_context->get_message_container( ).
  ENDIF.

  me->add_messages_from_bapi( it_bapi_messages = it_bapi_messages[]
                              iv_entity_type = iv_entity_type
                              it_key_tab = it_key_tab[]
                              iv_error_category = iv_error_category
                              iv_add_to_response_header = iv_add_to_response_header
                              iv_is_leading_message = iv_is_leading_message
                              io_message_container = lo_message_container
                              io_request_context = io_request_context ).

  RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
    EXPORTING
      message_container = lo_message_container
      entity_type       = iv_entity_type.

ENDMETHOD.


METHOD storagelocations_get_entityset.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_ZMM_PO_GOOD_RECEIP_DPC_EXTCM00B
*______________________________________________________________________________________*
* Date of creation: 25.03.2023 10:21:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Retourne la liste des entités StorageLocationSHSet selon les filtres
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  LOOP AT it_filter_select_options[] ASSIGNING FIELD-SYMBOL(<filter>).
    CASE <filter>-property.
      WHEN 'Plant'.
        DATA(lt_select_plant) = <filter>-select_options[].
      WHEN 'StorageLocation'.
        DATA(lt_select_storage_location) = <filter>-select_options[].
      WHEN 'Description'.
        DATA(lt_select_description) = <filter>-select_options[].
        "Convert to UPPER CASE
        LOOP AT lt_select_description[] ASSIGNING FIELD-SYMBOL(<select_desc>).
          <select_desc>-low = to_upper( <select_desc>-low ).
          <select_desc>-high = to_upper( <select_desc>-high ).
        ENDLOOP.
    ENDCASE.
  ENDLOOP.

  "Sélection de données selon filtres
  et_entityset[] = zcl_good_receipt_odata_helper=>get_storage_locations_sh_data(
                     it_sel_opt_plant            = lt_select_plant[]              "Filtre sur Division
                     it_sel_opt_storage_location = lt_select_storage_location[]   "Filtre sur Magasin
                     it_sel_opt_description      = lt_select_description[]        "Filtre sur Désignation Magasin
                 ).

  "Applique les tris
  me->apply_sorters( EXPORTING it_order    = it_order[]
                     CHANGING et_entityset = et_entityset[] ).
ENDMETHOD.
ENDCLASS.
