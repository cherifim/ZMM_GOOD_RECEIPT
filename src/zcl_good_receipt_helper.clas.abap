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
      END OF tys_po_file_upload.

    TYPES:
      tyt_po_file_uploads TYPE STANDARD TABLE OF tys_po_file_upload WITH DEFAULT KEY.

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
    CLASS-METHODS get_batches_for_items
      IMPORTING
        !it_items                    TYPE bapiekpo_tp
      RETURNING
        VALUE(rt_items_with_batches) TYPE tyt_po_items_batches .
protected section.
private section.
ENDCLASS.



CLASS ZCL_GOOD_RECEIPT_HELPER IMPLEMENTATION.


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


  "Lot
*  SELECT ebeln, ebelp, matnr, werks, zzlot_achat FROM ekpo INTO TABLE @DATA(lt_ekpo)
*  FOR ALL ENTRIES IN @lt_po_items[]
*  WHERE ebeln = @lt_po_items-po_number
*  AND   ebelp = @lt_po_items-po_item.
*
*  SELECT lot_achat, matnr, type FROM zmm_lot_achat
*    INTO TABLE @DATA(lt_zmm_lot_achat)
*    FOR ALL ENTRIES IN @lt_ekpo[]
*    WHERE lot_achat = @lt_ekpo-zzlot_achat
*    AND matnr = @lt_ekpo-matnr.
*  IF lt_zmm_lot_achat[] IS NOT INITIAL.
*    "Groupe de marchandise
*    SELECT matnr, matkl FROM mara
*      INTO TABLE @DATA(lt_mara)
*      FOR ALL ENTRIES IN @lt_zmm_lot_achat[]
*     WHERE matnr = @lt_zmm_lot_achat-matnr.
*    IF lt_mara[] IS NOT INITIAL.
*      "Check activation du lot achat
*      SELECT * INTO TABLE @DATA(lt_zmm_activ_la)
*        FROM zmm_activ_la
*        FOR ALL ENTRIES IN @lt_mara[]
*        WHERE matkl = @lt_mara-matkl.
*      "Sélection des divisions valide
*      SELECT low INTO TABLE @DATA(lt_tvarvc_zmm_speactiv_ls)
*        FROM tvarvc
*       WHERE name = 'ZMM_SPEACTIV_LS'.
*
*      "Vérification de la génération auto
*      SELECT low INTO TABLE @DATA(lt_tvarvc_zlot_stock_automatic)
*      FROM tvarvc
*      WHERE name = 'ZLOT_STOCK_AUTOMATIC'.
*    ENDIF.
*  ENDIF.
*
*
*  "Lot
*  ASSIGN lt_ekpo[ ebeln = <item>-po_number ebelp = <item>-po_item ] TO FIELD-SYMBOL(<ekpo>).
*  IF sy-subrc = 0.
*    ASSIGN lt_zmm_lot_achat[ lot_achat = <ekpo>-zzlot_achat matnr = <ekpo>-matnr type = 'T' ] TO FIELD-SYMBOL(<zmm_lot_achat>).
*    IF sy-subrc IS INITIAL.
*      ASSIGN lt_mara[ matnr = <zmm_lot_achat>-matnr ] TO FIELD-SYMBOL(<mara>).
*      IF sy-subrc IS INITIAL.
*        ASSIGN lt_zmm_activ_la[ matkl = <mara>-matkl werks = <ekpo>-werks ] TO FIELD-SYMBOL(<zmm_activ_la>).
*        IF sy-subrc IS INITIAL.
*          ASSIGN lt_tvarvc_zmm_speactiv_ls[ low = <zmm_activ_la>-werks ] TO FIELD-SYMBOL(<tvarvc_zmm_speactiv_ls>).
*          IF sy-subrc IS INITIAL.
*            <result>-batch_number = <ekpo>-zzlot_achat+2(7).
*          ENDIF.
*
*          ASSIGN lt_tvarvc_zlot_stock_automatic[ low = <zmm_activ_la>-werks ] TO FIELD-SYMBOL(<tvarvc_zlot_stock_automatic>).
*          IF sy-subrc IS INITIAL AND <result>-batch_number IS NOT INITIAL.
*            <result>-batch_number+7(3) = 'AAA'.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDIF.




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
  ENDIF.

  "TODO : upload attachment files ???

ENDMETHOD.
ENDCLASS.
