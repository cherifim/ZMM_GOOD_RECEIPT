class ZCL_GOOD_RECEIPT_ODATA_HELPER definition
  public
  final
  create public .

public section.

  class-methods GET_PURCHASE_ORDER_DATA
    importing
      !PO_NUMBER type EBELN
    returning
      value(RESULT) type ZMM_GR_S_PO_HEADER_ODATA .
  class-methods GET_PURCHASE_ORDER_ITEMS_DATA
    importing
      !PO_NUMBER type EBELN
      !IT_SEL_OPT_ITEM_NUMBERS type /IWBEP/T_COD_SELECT_OPTIONS optional
      !IT_SEL_OPT_REQ_TRCK_NUM type /IWBEP/T_COD_SELECT_OPTIONS optional
    returning
      value(RESULT) type ZMM_GR_T_PO_ITEM_ODATA .
  class-methods GET_BATCHES_SH_DATA
    importing
      !IT_SEL_OPT_MATERIAL_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_BATCH_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_VENDOR_ACCNT_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_VENDOR_BATCH_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
    returning
      value(RESULT) type ZMM_GR_T_BATCH_SH_ODATA .
  class-methods GET_PLANTS_SH_DATA
    importing
      !IT_SEL_OPT_PLANT type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_NAME type /IWBEP/T_COD_SELECT_OPTIONS
    returning
      value(RESULT) type ZMM_GR_T_PLANT_SH_ODATA .
  class-methods GET_STORAGE_LOCATIONS_SH_DATA
    importing
      !IT_SEL_OPT_PLANT type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_STORAGE_LOCATION type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_DESCRIPTION type /IWBEP/T_COD_SELECT_OPTIONS
    returning
      value(RESULT) type ZMM_GR_T_STORAGE_LOC_SH_ODATA .
  class-methods GET_PURCHASE_ORDERS_SH_DATA
    importing
      !IT_SEL_OPT_PO_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SET_OPT_COMPANY_CODE type /IWBEP/T_COD_SELECT_OPTIONS
      !IT_SEL_OPT_VENDOR_ACCNT_NUMBER type /IWBEP/T_COD_SELECT_OPTIONS
    returning
      value(RESULT) type ZMM_GR_T_PURCH_ORDER_SH_ODATA .
  class-methods SEL_OPT_CONVERSION_MATN1_INPUT
    changing
      !IT_SELECT_OPTIONS type /IWBEP/T_COD_SELECT_OPTIONS .
protected section.
private section.

  class-methods FIX_DATE
    importing
      !DATE type DATS
    returning
      value(FIXED_DATE) type DATS .
ENDCLASS.



CLASS ZCL_GOOD_RECEIPT_ODATA_HELPER IMPLEMENTATION.


METHOD fix_date.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM008
*______________________________________________________________________________________*
* Date of creation: 25.03.2023 16:24:31  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Force une date à 00000000 (format accepté par OData) si la date est vide
*                 ou si la date est invalide (trop ancienne)
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  IF date = '' OR date < '19000101'.
    fixed_date = '00000000'.
  ENDIF.

ENDMETHOD.


METHOD get_batches_sh_data.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM001
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 21:54:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Récupérer les données des lots pour entité OData BatchSH (aide à la recherche lots)
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  SELECT * FROM mch1 INTO TABLE @DATA(lt_mch1)
    WHERE charg IN @it_sel_opt_batch_number[] AND
          matnr IN @it_sel_opt_material_number[] AND
          lifnr IN @it_sel_opt_vendor_accnt_number[] AND
          licha IN @it_sel_opt_vendor_batch_number[].

  LOOP AT lt_mch1[] ASSIGNING FIELD-SYMBOL(<mch1>).
    APPEND INITIAL LINE TO result[] ASSIGNING FIELD-SYMBOL(<result>).
    <result>-batch_number = <mch1>-charg.
    <result>-material_number = <mch1>-matnr.
    <result>-vendor_account_number = <mch1>-lifnr.
    <result>-vendor_batch_number = <mch1>-licha.
  ENDLOOP.

ENDMETHOD.


METHOD get_plants_sh_data.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM001
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 21:54:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Récupérer les données des divisions pour entité OData PlantSH (aide à la recherche divisions)
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  SELECT * FROM t001w INTO TABLE @DATA(lt_t001w)
    WHERE werks IN @it_sel_opt_plant[].

  LOOP AT lt_t001w[] ASSIGNING FIELD-SYMBOL(<t001w>).
    "Filtre sur Nom
    IF to_upper( <t001w>-name1 ) NOT IN IT_SEL_OPT_NAME[].
      CONTINUE.
    ENDIF.

    APPEND INITIAL LINE TO result[] ASSIGNING FIELD-SYMBOL(<result>).
    <result>-plant = <t001w>-werks.
    <result>-name = <t001w>-name1.
  ENDLOOP.

ENDMETHOD.


  method GET_PURCHASE_ORDERS_SH_DATA.
  endmethod.


METHOD get_purchase_order_data.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM001
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 21:54:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Récupérer les données d'une commande d'achat pour entité OData PurchaseOrder
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: ls_po_header TYPE bapiekkol.
  DATA: lt_po_items TYPE STANDARD TABLE OF bapiekpo.
  DATA: lt_return TYPE STANDARD TABLE OF bapiret2.
  DATA: lt_po_header_txts TYPE STANDARD TABLE OF bapiekkotx.
  DATA: lt_delivery_addr TYPE bapimepoaddrdelivery_tp.
  DATA: lt_delivery_addr_all TYPE bapimepoaddrdelivery_tp.

  "Vérifier l'existance du numéro de commande d'achat
  SELECT SINGLE ebeln FROM ekko INTO @DATA(ls_ekko)
    WHERE ebeln = @po_number AND
          bstyp = 'F' AND "Catégorie = Commande d'Achat
          bsart = 'ZANB'. "Type document = Commande d'Achat
  CHECK sy-subrc = 0.

  result-purchase_order_number = po_number.

  "Récupérer les données de la commande d'achat
  CALL FUNCTION 'BAPI_PO_GETDETAIL'
    EXPORTING
      purchaseorder   = po_number
      items           = abap_true
      header_texts    = abap_true
    IMPORTING
      po_header       = ls_po_header
*     po_address      = ls_po_address
    TABLES
      po_header_texts = lt_po_header_txts
      po_items        = lt_po_items[].

  result-company_code = ls_po_header-co_code.
  result-document_category = ls_po_header-doc_cat.
  result-document_type = ls_po_header-doc_type.
  result-document_date = fix_date( ls_po_header-doc_date ).
  result-vendor_account_number = ls_po_header-vendor.
  result-vendor_name = ls_po_header-vend_name.
  result-document_posting_date = sy-datum.


  "Selection de descriptions du groupe acheteur
  SELECT SINGLE eknam FROM t024 INTO result-purchasing_group_desc
    WHERE ekgrp = ls_po_header-pur_group.

  "Sélection du N° de téléphone du fournisseur
  SELECT SINGLE telf1 FROM lfa1 INTO result-vendor_telephone_number
    WHERE lifnr = ls_po_header-vendor.


  "Adresse de livraison:
  LOOP AT lt_po_items[] ASSIGNING FIELD-SYMBOL(<item>). "Récupérer les adresses de livraison de tous les postes
    "Adresse de livraison
    CLEAR lt_delivery_addr[].
    CALL FUNCTION 'Z_GET_PO_DELIVERY_ADDRESS'
      EXPORTING
        im_ebeln       = po_number
        im_ebelp       = <item>-po_item
      CHANGING
        ct_del_address = lt_delivery_addr[].

    APPEND LINES OF lt_delivery_addr[] TO lt_delivery_addr_all[].
  ENDLOOP.

  SORT lt_delivery_addr_all[] BY addr_no.
  DELETE ADJACENT DUPLICATES FROM lt_delivery_addr_all[] COMPARING addr_no.


  IF lines( lt_delivery_addr[] ) <= 1. "Une seule adresse trouvée pour tous les postes

    result-unique_delivery_adr = abap_true.

    ASSIGN lt_delivery_addr_all[ 1 ] TO FIELD-SYMBOL(<delivery_addr>).
    IF sy-subrc = 0.
      result-address_name = <delivery_addr>-name.
      result-city = <delivery_addr>-city.
      result-zip_code = <delivery_addr>-postl_cod1.
      result-street = <delivery_addr>-street.
      result-house_num = <delivery_addr>-house_no.
      result-country_code = <delivery_addr>-country.
    ENDIF.

  ENDIF.

  "Textes d'en-tête
  LOOP AT lt_po_header_txts[] ASSIGNING FIELD-SYMBOL(<header_txt>) WHERE text_id = 'F01'.
    AT FIRST.
      result-purchase_order_header_txt = <header_txt>-text_line.
      CONTINUE.
    ENDAT.
    result-purchase_order_header_txt = result-purchase_order_header_txt && cl_abap_char_utilities=>cr_lf && <header_txt>-text_line.
  ENDLOOP.

ENDMETHOD.


METHOD get_purchase_order_items_data.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM005
*______________________________________________________________________________________*
* Date of creation: 25.03.2023 18:00:35  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Récupérer les données des postes d'une commande d'achat pour l'entité OData PurchaseOrderItem
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  DATA: lt_po_items TYPE STANDARD TABLE OF bapiekpo.
  DATA: lt_return TYPE STANDARD TABLE OF bapiret2.
  DATA: lt_pr_items TYPE STANDARD TABLE OF bapieban.
  DATA: lt_po_items_txts TYPE STANDARD TABLE OF bapiekpotx.
  DATA: ls_user_address TYPE bapiaddr3.
  DATA: lt_item_account_assignment TYPE STANDARD TABLE OF bapiekkn.
  DATA: lt_i_wbs_element TYPE STANDARD TABLE OF	bapi_wbs_elements.
  DATA: lt_e_wbs_element TYPE STANDARD TABLE OF bapi_wbs_element_exp.
  DATA: lt_delivery_addr TYPE bapimepoaddrdelivery_tp.

  "Vérifier l'existance du numéro de commande d'achat
  SELECT SINGLE ebeln FROM ekko INTO @DATA(ls_ekko)
    WHERE ebeln = @po_number AND
          bstyp = 'F' AND "Catégorie = Commande d'Achat
          bsart = 'ZANB'. "Type document = Commande d'Achat
  CHECK sy-subrc = 0.

  "Récupérer les données de la commande d'achat (postes)
  CALL FUNCTION 'BAPI_PO_GETDETAIL'
    EXPORTING
      purchaseorder              = po_number
      items                      = abap_true
      account_assignment         = abap_true
      item_texts                 = abap_true
    TABLES
      po_items                   = lt_po_items[]
      po_item_account_assignment = lt_item_account_assignment[]
      po_item_texts              = lt_po_items_txts[].


  CHECK lt_po_items[] IS NOT INITIAL.

  "Selection de descriptions de certains objets (divisions/magasins/articles)
  "Division
  SELECT werks, name1 FROM t001w INTO TABLE @DATA(lt_t001w)
    FOR ALL ENTRIES IN @lt_po_items[]
    WHERE werks = @lt_po_items-plant.

  "Magasins
  SELECT werks, lgort, lgobe FROM t001l INTO TABLE @DATA(lt_t001l)
    FOR ALL ENTRIES IN @lt_po_items[]
    WHERE werks = @lt_po_items-plant AND
          lgort = @lt_po_items-store_loc.

  "Articles
  SELECT matnr, spras, maktx FROM makt INTO TABLE @DATA(lt_makt)
    FOR ALL ENTRIES IN @lt_po_items[]
    WHERE matnr = @lt_po_items-material.

  "Centre de coût
  SELECT * FROM cskt INTO TABLE @DATA(lt_cskt)
    FOR ALL ENTRIES IN @lt_item_account_assignment[]
    WHERE kokrs = @lt_item_account_assignment-co_area AND
          kostl = @lt_item_account_assignment-cost_ctr AND
          datbi > @sy-datum AND
          spras = @sy-langu.
  SORT lt_cskt[] BY datbi ASCENDING.

  "Récupérer les lots pour chaque item
  DATA(lt_items_batches) = zcl_good_receipt_helper=>get_batches_for_items( lt_po_items[] ).

  "Elements d'OTP
  lt_i_wbs_element[] = VALUE #( FOR ls_assignment IN lt_item_account_assignment[] ( wbs_element = ls_assignment-wbs_elem_e ) ).

  CALL FUNCTION 'BAPI_PROJECT_GETINFO'
    TABLES
      i_wbs_element_table = lt_i_wbs_element[]
      e_wbs_element_table = lt_e_wbs_element[].

  "Sélection des échéances de livraison
  SELECT ebeln, ebelp, menge, wemng FROM eket INTO TABLE @DATA(lt_eket)
    FOR ALL ENTRIES IN @lt_po_items[]
    WHERE ebeln = @lt_po_items-po_number
    AND   ebelp = @lt_po_items-po_item.

  LOOP AT lt_po_items[] ASSIGNING FIELD-SYMBOL(<item>).

    CHECK <item>-po_item IN it_sel_opt_item_numbers[].
    CHECK <item>-trackingno IN it_sel_opt_req_trck_num[].

    APPEND INITIAL LINE TO result[] ASSIGNING FIELD-SYMBOL(<result>).

    <result>-purchase_order_number = po_number.
    <result>-item_number = <item>-po_item.

    "Division
    <result>-plant = <item>-plant.
    ASSIGN lt_t001w[ werks = <item>-plant ] TO FIELD-SYMBOL(<t001w>).
    IF sy-subrc = 0.
      <result>-plant_name = <t001w>-name1.
    ENDIF.

    "Magasin
    <result>-storage_location = <item>-store_loc.
    ASSIGN lt_t001l[ werks = <item>-plant lgort = <item>-store_loc ] TO FIELD-SYMBOL(<t001l>).
    IF sy-subrc = 0.
      <result>-storage_location_desc = <t001l>-lgobe.
    ENDIF.

    "Article
    <result>-material_number = <item>-material.
    ASSIGN lt_makt[ matnr = <item>-material spras = sy-langu ] TO FIELD-SYMBOL(<makt>).
    IF sy-subrc = 0.
      <result>-material_desc = <makt>-maktx.
    ELSE. "Non trouvé avec langue connexion -> essayer toute autre langue
      ASSIGN lt_makt[ matnr = <item>-material ] TO <makt>.
      <result>-material_desc = <makt>-maktx.
    ENDIF.

    <result>-purchase_order_quantity = <item>-quantity.
    <result>-purchase_order_unit = <item>-unit.

    "N° de besoin
    <result>-requirement_tracking_number = <item>-trackingno.

    "Designation
    <result>-designation = <item>-short_text.

    "Adresse de livraison:
    CALL FUNCTION 'Z_GET_PO_DELIVERY_ADDRESS'
      EXPORTING
        im_ebeln       = po_number
        im_ebelp       = <item>-po_item
      CHANGING
        ct_del_address = lt_delivery_addr[].

    ASSIGN lt_delivery_addr[ 1 ] TO FIELD-SYMBOL(<delivery_addr>).
    IF sy-subrc IS INITIAL.
      <result>-address_name = <delivery_addr>-name.
      <result>-city = <delivery_addr>-city.
      <result>-zip_code = <delivery_addr>-postl_cod1.
      <result>-street = <delivery_addr>-street.
      <result>-house_num = <delivery_addr>-house_no.
      <result>-country_code = <delivery_addr>-country.
    ENDIF.

    "Créé par
    "Sélection du créateur de la DA
    IF <item>-preq_no IS NOT INITIAL AND <item>-preq_item IS NOT INITIAL.
      CALL FUNCTION 'BAPI_REQUISITION_GETDETAIL'
        EXPORTING
          number            = <item>-preq_no
        TABLES
          requisition_items = lt_pr_items[]
          return            = lt_return[].

      ASSIGN lt_pr_items[ preq_no = <item>-preq_no preq_item = <item>-preq_item ] TO FIELD-SYMBOL(<pr_item>).
      IF sy-subrc = 0.
        <result>-creator_user = <pr_item>-created_by.

        "Récupérer le nom du créateur de la DA
        CALL FUNCTION 'BAPI_USER_GET_DETAIL'
          EXPORTING
            username = <pr_item>-created_by
          IMPORTING
            address  = ls_user_address
          TABLES
            return   = lt_return[].

        <result>-creator_name = ls_user_address-fullname.
      ENDIF.
    ENDIF.

    "Textes de poste
    LOOP AT lt_po_items_txts[] ASSIGNING FIELD-SYMBOL(<item_txt>) WHERE po_item = <item>-po_item AND text_id = 'F01'.
      AT FIRST.
        <result>-purchase_order_item_txt = <item_txt>-text_line.
        CONTINUE.
      ENDAT.
      <result>-purchase_order_item_txt = <result>-purchase_order_item_txt && cl_abap_char_utilities=>cr_lf && <item_txt>-text_line.
    ENDLOOP.

    "Centre de coût et l'éOTP
    ASSIGN lt_item_account_assignment[ po_item = <item>-po_item ] TO FIELD-SYMBOL(<item_account_assign>).
    IF sy-subrc = 0.

      "Centre de coût
      IF <item_account_assign>-cost_ctr IS NOT INITIAL.
        <result>-cost_center = <item_account_assign>-cost_ctr.
        ASSIGN lt_cskt[ kokrs = <item_account_assign>-co_area kostl = <item_account_assign>-cost_ctr ] TO FIELD-SYMBOL(<cskt>).
        IF sy-subrc = 0.
          <result>-cost_center_name = <cskt>-ktext.
          <result>-cost_center_desc = <cskt>-ltext.
        ENDIF.
      ENDIF.

      "Elément d'OTP
      IF <item_account_assign>-wbs_elem_e IS NOT INITIAL.
        <result>-wbs_element = <item_account_assign>-wbs_elem_e.
        ASSIGN lt_e_wbs_element[ wbs_element = <item_account_assign>-wbs_elem_e ] TO FIELD-SYMBOL(<e_wbs_element>).
        IF sy-subrc = 0.
          <result>-wbs_element_desc = <e_wbs_element>-description.
        ENDIF.
      ENDIF.

    ENDIF.

    "Quantité Restante
    LOOP AT lt_eket[] ASSIGNING FIELD-SYMBOL(<eket>) WHERE ebeln = <item>-po_number AND ebelp = <item>-po_item.
      <result>-remaining_quantity = <result>-remaining_quantity + <eket>-menge - <eket>-wemng.
    ENDLOOP.

    "Quantité entrée (initialisée avec la quantité restante)
    <result>-receipt_quantity = <result>-remaining_quantity.

    "Lot
    ASSIGN lt_items_batches[ purchase_order_number = po_number item_number = <item>-po_item ] TO FIELD-SYMBOL(<item_batch>).
    IF sy-subrc = 0.
      <result>-batch_number = <item_batch>-batch.
    ENDIF.

  ENDLOOP.

ENDMETHOD.


METHOD get_storage_locations_sh_data.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM001
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 21:54:45  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description : Récupérer les données des magasins pour entité OData StorageLocationSH (aide à la recherche)
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  SELECT * FROM t001l INTO TABLE @DATA(lt_t001l)
    WHERE werks IN @it_sel_opt_plant[] AND
          lgort IN @it_sel_opt_storage_location.

  LOOP AT lt_t001l[] ASSIGNING FIELD-SYMBOL(<t001l>).
    "Filtre sur la designation
    IF to_upper( <t001l>-lgobe ) NOT IN it_sel_opt_description[].
      CONTINUE.
    ENDIF.

    APPEND INITIAL LINE TO result[] ASSIGNING FIELD-SYMBOL(<result>).
    <result>-plant = <t001l>-werks.
    <result>-storage_location = <t001l>-lgort.
    <result>-description = <t001l>-lgobe.

  ENDLOOP.

ENDMETHOD.


METHOD sel_opt_conversion_matn1_input.
*______________________________________________________________________________________*
* Description:
* See object description
* Techname: ZCL_GOOD_RECEIPT_ODATA_HELPER=CM007
*______________________________________________________________________________________*
* Date of creation: 24.03.2023 22:59:16  / Author: MCHERIFI / Mourad CHERIFI (STMS)
* Reference document:
*  Description :  Applique la conversion MATN1 sur un select options
*______________________________________________________________________________________*
* Historic of modifications
* Date / User name / Transport request / VYY-NN <Free>
* Description:
*______________________________________________________________________________________*

  "Inbound conversion Material number  (convert 123 into 000000000000000123)
  LOOP AT it_select_options[] ASSIGNING FIELD-SYMBOL(<sel_opt>) WHERE option <> 'CP' AND option <> 'NP'.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = <sel_opt>-low
      IMPORTING
        output       = <sel_opt>-low
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = <sel_opt>-high
      IMPORTING
        output       = <sel_opt>-high
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
    ENDIF.
  ENDLOOP.

ENDMETHOD.
ENDCLASS.
