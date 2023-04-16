CLASS zcl_good_receipt_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF tys_po_item_input,
        item_number         TYPE ebelp,
        purchase_order_unit TYPE bstme,
        receipt_quantity    TYPE wemng,
      END OF tys_po_item_input .
    TYPES:
      tyt_po_item_input TYPE STANDARD TABLE OF tys_po_item_input WITH DEFAULT KEY .
    TYPES:
      BEGIN OF tys_po_file_upload,
        file_name    TYPE zmm_gr_file_name,
        file_content TYPE zmm_gr_file_content,
        mime_type    TYPE zmm_gr_file_mime_type,
        is_url       TYPE zmm_gr_is_url,
        url          TYPE zmm_gr_url,
      END OF tys_po_file_upload .
    TYPES:
      tyt_po_file_uploads TYPE STANDARD TABLE OF tys_po_file_upload WITH DEFAULT KEY .
    TYPES:
      BEGIN OF tys_po_header_input,
        purchase_order_number TYPE ebeln,
        document_posting_date TYPE budat,
        document_header_text  TYPE bktxt,
        delivery_note         TYPE lfsnr1,
        items                 TYPE tyt_po_item_input,
        files                 TYPE tyt_po_file_uploads,
      END OF tys_po_header_input .
    TYPES:
      tyt_po_header_input TYPE STANDARD TABLE OF tys_po_header_input WITH DEFAULT KEY .
    TYPES:
      BEGIN OF tys_po_items_batch,
        purchase_order_number TYPE ebeln,
        item_number           TYPE ebelp,
        batch                 TYPE charg_d,
      END OF tys_po_items_batch .
    TYPES:
      tyt_po_items_batches TYPE STANDARD TABLE OF tys_po_items_batch WITH DEFAULT KEY .

    CLASS-METHODS perform_po_good_receipt
      IMPORTING
        !is_po_input  TYPE tys_po_header_input
      RETURNING
        VALUE(return) TYPE bapiret2_tt .
    CLASS-METHODS attach_good_receipt_documents
      IMPORTING
        !iv_material_doc_number TYPE mblnr
        !iv_material_doc_year   TYPE mjahr
        !it_file_uploads        TYPE tyt_po_file_uploads
      RETURNING
        VALUE(return)           TYPE bapiret2_tt .
    CLASS-METHODS get_batches_for_items
      IMPORTING
        !it_items                    TYPE bapiekpo_tp
      RETURNING
        VALUE(rt_items_with_batches) TYPE tyt_po_items_batches .
protected section.
private section.
ENDCLASS.



CLASS ZCL_GOOD_RECEIPT_HELPER IMPLEMENTATION.


METHOD attach_good_receipt_documents.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_HELPER=======CM004
*______________________________________________________________________________________*
* Date of creation: 12.04.2023 16:40:51  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Charge des pièces jointes sur l'entrée marchandise
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: ls_fol_id TYPE soodk.
  DATA: ls_obj_data TYPE sood1. "object definition and change attributes
  DATA: lv_output_len TYPE integer. "Taille du fichier
  DATA: ls_obj_id TYPE soodk. "definition of an object (key part)
  DATA: lv_object_type TYPE so_obj_tp.
  DATA: lt_objhead TYPE STANDARD TABLE OF soli.
  DATA: lt_solix TYPE solix_tab.
  DATA: lt_soli TYPE soli_tab.
  DATA: ls_sofmk TYPE sofmk. "folder content data
  DATA: ls_good_receipt_object TYPE borident.
  DATA: ls_attach_obj TYPE borident.
  DATA: lv_relation_type TYPE binreltyp.

  " Get folder root id
  CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
    EXPORTING
      region                = 'B'
    IMPORTING
      folder_id             = ls_fol_id
    EXCEPTIONS
      communication_failure = 1
      owner_not_exist       = 2
      system_failure        = 3
      x_error               = 4
      OTHERS                = 5.

  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E'
                    id = 'ZMM_GOOD_RECEIPT'
                    number = 009 "Erreur pièce jointe : &1 &2 &3 &4
                    message_v1 = 'SO_FOLDER_ROOT_ID_GET'
                    message_v2 = |SUBRC = { sy-subrc }| )
           TO return[].
    RETURN.
  ENDIF.


  LOOP AT it_file_uploads[] ASSIGNING FIELD-SYMBOL(<file>).

    CLEAR ls_obj_data.
    CLEAR lt_solix[].
    CLEAR lt_soli[].
    CLEAR lt_objhead[].
    CLEAR ls_attach_obj.
    CLEAR ls_good_receipt_object.

    IF <file>-is_url = abap_false. "Cas upload de fichier avec contenu

      lv_object_type = 'EXT'. "Document PC
      lv_relation_type = 'ATTA'. "Attachment

      "Conversion XSTRING -> BINARY
      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING
          buffer        = <file>-file_content "is_media_resource-value "xstring
        IMPORTING
          output_length = lv_output_len
        TABLES
          binary_tab    = lt_solix[].

      "Conversion SOLIXTAB -> SOLITAB
      CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
        EXPORTING
          ip_solixtab = lt_solix[]
        IMPORTING
          ep_solitab  = lt_soli[].

      "Calculer l'extension du fichier
      SPLIT <file>-file_name AT '.' INTO TABLE DATA(lt_str).
      DATA(lv_tokens) = lines( lt_str[] ).
      IF lv_tokens > 0.
        ASSIGN lt_str[ lv_tokens ] TO FIELD-SYMBOL(<str>).
        IF sy-subrc = 0.
          ls_obj_data-file_ext = to_upper( <str> ).
        ENDIF.
      ENDIF.

      "ls_obj_data-objsns = c_o. "sensitivity of object (o-standard)
      ls_obj_data-objlen = lv_output_len.

      lt_objhead = VALUE #( ( line = '&SO_FILENAME=' && <file>-file_name )
                            ( line = '&SO_FORMAT=BIN' )
                            ( line = '&SO_CONTTYPE=' && <file>-mime_type ) ).
    ELSE. "Cas URL
      lv_object_type = 'URL'.
      lv_relation_type = 'URL'. "Attachment

      lt_soli[] = VALUE #( ( line = '&KEY&' && <file>-url ) ).
    ENDIF.

    ls_obj_data-objla = sy-langu. "language
    ls_obj_data-objdes = <file>-file_name.
    ls_obj_data-objsns = 'O'. "Sensitivité = Standard

    "Insert file into the folder
    CALL FUNCTION 'SO_OBJECT_INSERT'
      EXPORTING
        folder_id                  = ls_fol_id
        object_type                = lv_object_type
        object_hd_change           = ls_obj_data
      IMPORTING
        object_id                  = ls_obj_id
      TABLES
        objhead                    = lt_objhead[]
        objcont                    = lt_soli[]
      EXCEPTIONS
        active_user_not_exist      = 1
        communication_failure      = 2
        component_not_available    = 3
        dl_name_exist              = 4
        folder_not_exist           = 5
        folder_no_authorization    = 6
        object_type_not_exist      = 7
        operation_no_authorization = 8
        owner_not_exist            = 9
        parameter_error            = 10
        substitute_not_active      = 11
        substitute_not_defined     = 12
        system_failure             = 13
        x_error                    = 14
        OTHERS                     = 15.

    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E'
                      id = 'ZMM_GOOD_RECEIPT'
                      number = 009 "Erreur pièce jointe : &1 &2 &3 &4
                      message_v1 = 'SO_OBJECT_INSERT'
                      message_v2 = |SUBRC = { sy-subrc }|
                      message_v3 = |FILE = { <file>-file_name }| )
             TO return[].
      RETURN.
    ENDIF.

    "Créer la relation binaire entre le fichier et l'objet  A (Document entrée de marchandise) --> B (Fichier pièce jointe)
    "Objet A
    ls_good_receipt_object-objkey = iv_material_doc_number && iv_material_doc_year.
    ls_good_receipt_object-objtype = 'BUS2017'. "Business Number = Mouvement de Stock


    "Objet B
    ls_sofmk-foltp = ls_fol_id-objtp.
    ls_sofmk-folyr = ls_fol_id-objyr.
    ls_sofmk-folno = ls_fol_id-objno.
    ls_sofmk-doctp = ls_obj_id-objtp.
    ls_sofmk-docyr = ls_obj_id-objyr.
    ls_sofmk-docno = ls_obj_id-objno.

    ls_attach_obj-objkey = ls_sofmk.
    ls_attach_obj-objtype = 'MESSAGE'.
    "CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.

    CALL FUNCTION 'BINARY_RELATION_CREATE'
      EXPORTING
        obj_rolea      = ls_good_receipt_object
        obj_roleb      = ls_attach_obj
        relationtype   = lv_relation_type
      EXCEPTIONS
        no_model       = 1
        internal_error = 2
        unknown        = 3.

    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E'
                      id = 'ZMM_GOOD_RECEIPT'
                      number = 009 "Erreur pièce jointe : &1 &2 &3 &4
                      message_v1 = 'BINARY_RELATION_CREATE'
                      message_v2 = |SUBRC = { sy-subrc }|
                      message_v3 = |FILE = { <file>-file_name }| )
             TO return[].
      RETURN.
    ENDIF.

    "Succès
    APPEND VALUE #( type = 'S'
                    id = 'ZMM_GOOD_RECEIPT'
                    number = 010 "La pièce jointe &1 a été attachée au document article &2
                    message_v1 = <file>-file_name
                    message_v2 = iv_material_doc_number )
           TO return[].

  ENDLOOP.


ENDMETHOD.


METHOD get_batches_for_items.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_HELPER=======CM003
*______________________________________________________________________________________*
* Date of creation: 05.04.2023 20:23:42  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : calcule le lot pour chaque poste de commande d'achat
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lv_batch TYPE charg_d.

  SELECT ekpo~ebeln AS ebeln,
         ekpo~ebelp AS ebelp,
         ekpo~zzlot_achat AS zzlot_achat,
         tvarvc_stock_automatic~low AS werks_stock_automatic
    FROM ekpo AS ekpo
    INNER JOIN ekko AS ekko
      ON  ekko~ebeln = ekpo~ebeln
    INNER JOIN zmm_lot_achat AS zmm_lot_achat
      ON zmm_lot_achat~lot_achat = ekpo~zzlot_achat AND
         zmm_lot_achat~matnr = ekpo~matnr AND
         zmm_lot_achat~type = 'T'
    INNER JOIN mara AS mara
      ON mara~matnr = ekpo~matnr
    INNER JOIN zmm_activ_la AS zmm_activ_la
      ON zmm_activ_la~matkl = mara~matkl AND
         zmm_activ_la~werks = ekpo~werks AND
         zmm_activ_la~bstyp = ekko~bstyp AND
         zmm_activ_la~bsart = ekko~bsart
    INNER JOIN tvarvc AS tvarvc_speactiv_ls
      ON tvarvc_speactiv_ls~name = 'ZMM_SPEACTIV_LS' AND
         tvarvc_speactiv_ls~low = zmm_activ_la~werks
    LEFT OUTER JOIN tvarvc AS tvarvc_stock_automatic
      ON tvarvc_stock_automatic~name = 'ZLOT_STOCK_AUTOMATIC' AND
         tvarvc_stock_automatic~low = zmm_activ_la~werks
    INTO TABLE @DATA(lt_join_result)
    FOR ALL ENTRIES IN @it_items[]
    WHERE ekpo~ebeln = @it_items-po_number AND
          ekpo~ebelp = @it_items-po_item.

  IF sy-subrc = 0.
    LOOP AT it_items[] ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN lt_join_result[ ebeln = <item>-po_number ebelp = <item>-po_item ] TO FIELD-SYMBOL(<join_result>).
      IF sy-subrc = 0.
        APPEND INITIAL LINE TO rt_items_with_batches[] ASSIGNING FIELD-SYMBOL(<item_batch>).
        <item_batch>-purchase_order_number = <item>-po_number.
        <item_batch>-item_number = <item>-po_item.
        <item_batch>-batch = <join_result>-zzlot_achat+2(7).
        IF <join_result>-werks_stock_automatic IS NOT INITIAL.
          <item_batch>-batch+7(3) = 'AAA'.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.


ENDMETHOD.


METHOD perform_po_good_receipt.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_HELPER=======CM001
*______________________________________________________________________________________*
* Date of creation: 02.04.2023 19:40:51  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Exécute une entrée de marchandise sur une commande d'achat
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lt_po_items TYPE STANDARD TABLE OF bapiekpo.
  DATA: ls_goodsmvt_header TYPE bapi2017_gm_head_01.
  DATA: ls_goodsmvt_headret TYPE bapi2017_gm_head_ret.
  DATA: lv_materialdocument TYPE mblnr.
  DATA: lv_matdocumentyear TYPE mjahr.
  DATA: lt_item_account_assignment TYPE STANDARD TABLE OF bapiekkn.
  DATA: lt_goodsmvt_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.

  "Récupérer les données de la commande d'achat (postes)
  CALL FUNCTION 'BAPI_PO_GETDETAIL'
    EXPORTING
      purchaseorder              = is_po_input-purchase_order_number
      items                      = abap_true
      account_assignment         = abap_true
    TABLES
      po_items                   = lt_po_items[]
      po_item_account_assignment = lt_item_account_assignment[].

  "Récupérer les lots pour les postes
  DATA(lt_items_batches) = get_batches_for_items( lt_po_items[] ).

  "Données entête
  ls_goodsmvt_header-pstng_date = is_po_input-document_posting_date. "Date comptable
  ls_goodsmvt_header-doc_date = is_po_input-document_posting_date.
  ls_goodsmvt_header-ref_doc_no = is_po_input-delivery_note. "Bon de livraison
  ls_goodsmvt_header-header_txt = is_po_input-document_header_text. "Note

  "Données postes
  LOOP AT is_po_input-items[] ASSIGNING FIELD-SYMBOL(<item>).

    ASSIGN lt_po_items[ po_number = is_po_input-purchase_order_number
                        po_item   = <item>-item_number ] TO FIELD-SYMBOL(<po_item>).
    CHECK sy-subrc = 0.

    APPEND INITIAL LINE TO lt_goodsmvt_item[] ASSIGNING FIELD-SYMBOL(<goodsmvt_item>).

    <goodsmvt_item>-po_number = is_po_input-purchase_order_number.
    <goodsmvt_item>-po_item = <item>-item_number.
    <goodsmvt_item>-plant = <po_item>-plant.       "Division
    <goodsmvt_item>-stge_loc = <po_item>-store_loc.   "Emplacement de stockage
    <goodsmvt_item>-move_type = '101'.   " Code mvt - Entrée de marchandise
    <goodsmvt_item>-mvt_ind = 'B'.
    <goodsmvt_item>-entry_qnt = <item>-receipt_quantity.

    ASSIGN lt_items_batches[ purchase_order_number = <goodsmvt_item>-po_number item_number = <goodsmvt_item>-po_item ] TO FIELD-SYMBOL(<batch>).
    IF sy-subrc = 0.
      <goodsmvt_item>-batch = <batch>-batch.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
    EXPORTING
      goodsmvt_header  = ls_goodsmvt_header
      goodsmvt_code    = '01' "GM_Code 01: Entrée de marchandises pour CA
*     TESTRUN          = ' '
*     GOODSMVT_REF_EWM =
    IMPORTING
      goodsmvt_headret = ls_goodsmvt_headret
      materialdocument = lv_materialdocument
      matdocumentyear  = lv_matdocumentyear
    TABLES
      goodsmvt_item    = lt_goodsmvt_item[]
      return           = return[]
*     GOODSMVT_SERV_PART_DATA       =
*     EXTENSIONIN      =
    .

  "Mouvement d'entrée de marchandise effectué avec succès
  IF lv_materialdocument IS NOT INITIAL.

    APPEND VALUE #( type = 'S'
                    id = 'ZMM_GOOD_RECEIPT'
                    number = 007
                    message_v1 = is_po_input-purchase_order_number
                    message_v2 = lv_materialdocument ) "Entrée de marchandise sur CA &1 effectuée avec succès (N°Doc &2)
           TO return[].

    "Charger les pièces jointes (GOS)
    IF is_po_input-files[] IS NOT INITIAL.
      DATA(lt_return) = attach_good_receipt_documents( iv_material_doc_number = lv_materialdocument
                                                       iv_material_doc_year = lv_matdocumentyear
                                                       it_file_uploads    = is_po_input-files[] ).
      APPEND LINES OF lt_return[] TO return[].
    ENDIF.

  ENDIF.

  IF line_exists( lt_return[ type = 'E' ] ). "Erreur lors du chargement des pièces jointes
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

ENDMETHOD.
ENDCLASS.
