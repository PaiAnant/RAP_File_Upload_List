CLASS lhc_List DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR List RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR List RESULT result.

    METHODS downloadTemplate FOR MODIFY
      IMPORTING keys FOR ACTION List~downloadTemplate.

    METHODS ExcelUpload FOR MODIFY
      IMPORTING keys FOR ACTION List~ExcelUpload.
    METHODS uploadData FOR MODIFY
      IMPORTING keys FOR ACTION List~uploadData.

ENDCLASS.

CLASS lhc_List IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD downloadTemplate.
  ENDMETHOD.


  METHOD ExcelUpload.

    DATA lv_attachment   TYPE xstring.

    DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lv_content      TYPE string,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lt_excel        TYPE STANDARD TABLE OF zbp_i_upload_list=>gty_gr_xl,
          lt_data         TYPE TABLE FOR CREATE zi_upload_list,
          lv_index        TYPE sy-index.

    FIELD-SYMBOLS: <lfs_col_header> TYPE string.

    lv_attachment = VALUE #( keys[ 1 ]-%param-_streamproperties-FileBase64 OPTIONAL ).

    READ ENTITIES OF zi_upload_list IN LOCAL MODE
    ENTITY List
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_ulpoad_list).

    "Move Excel Data to Internal Table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
        iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select(
        lo_selection_pattern )->row_stream( )->operation->write_to(
            REF #( lt_excel ) ).
    lo_execute->set_value_transformation(
        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    " Get number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        "Implement error handling
    ENDTRY.

    IF lt_excel IS NOT INITIAL.
      "Validate Header record
      DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
      IF ls_excel IS NOT INITIAL.
        DO lv_no_of_cols TIMES.
          lv_index = sy-index.
          ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
          CHECK <lfs_col_header> IS ASSIGNED.
          DATA(lv_value) = to_upper( <lfs_col_header> ).
          DATA(lv_has_error) = abap_false.
          CASE lv_index.
            WHEN 1.
              lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
            WHEN 2.
              lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
            WHEN 3.
              lv_has_error = COND #( WHEN lv_value <> 'QUANTITY' THEN abap_true ELSE lv_has_error ).
            WHEN 4.
              lv_has_error = COND #( WHEN lv_value <> 'UOM' THEN abap_true ELSE lv_has_error ).
            WHEN 5.
              lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
            WHEN 6.
              lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
            WHEN 9. "More than 7 columns (error)
              lv_has_error = abap_true.
          ENDCASE.
          IF lv_has_error = abap_true.
            APPEND VALUE #( %tky = lt_ulpoad_list[ 1 ]-%tky ) TO failed-list.
            APPEND VALUE #(
              %tky = lt_ulpoad_list[ 1 ]-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'Wrong File Format!!' )
            ) TO reported-list.
            UNASSIGN <lfs_col_header>.
            EXIT.
          ENDIF.
          UNASSIGN <lfs_col_header>.
        ENDDO.
      ENDIF.
      CHECK lv_has_error = abap_false.

      DATA(lt_file_data) = lt_excel[].

      DELETE lt_file_data INDEX 1.

      DELETE lt_file_data WHERE po_number IS INITIAL.

      "Fill Line ID / Line Number

      LOOP AT lt_file_data ASSIGNING FIELD-SYMBOL(<lfs_excel>).

        TRY.
*          DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
            <lfs_excel>-line_id = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

*        <lfs_excel>-line_id     = lv_line_id.
        <lfs_excel>-line_number = sy-tabix.
      ENDLOOP.

      lt_data = VALUE #( FOR lwa_excel IN lt_file_data (
                                LineId          = lwa_excel-line_id
                         LineNum         = lwa_excel-line_number
                         PoNumber        = lwa_excel-po_number
                         PoItem          = lwa_excel-po_item
                         GrUantity      = lwa_excel-gr_quantity
                         UnitOfMeasure   = lwa_excel-unit_of_measure
                         SiteId          = lwa_excel-site_id
                         HeaderText      = lwa_excel-header_text
       ) ).

      "Delete Existing entry for user if any

      SELECT *
       FROM ztb_upload_list
       INTO TABLE @DATA(lt_LineId).

      DATA lt_del TYPE TABLE FOR DELETE zi_upload_list.

      lt_del = VALUE #( FOR x IN lt_LineId ( lineid = x-line_id LineNum = x-line_no ) ).

      IF lt_del IS NOT INITIAL.

        MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
         ENTITY List
         DELETE FROM lt_del
         FAILED   DATA(lt_failed)
         REPORTED DATA(lt_reported)
         MAPPED   DATA(lt_mapped).

      ENDIF.

      MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
       ENTITY List
       CREATE AUTO FILL CID FIELDS ( LineId LineNum PoNumber PoItem SiteId GrUantity UnitOfMeasure HeaderText )
       WITH lt_data
       MAPPED DATA(ls_mapped_u)
       FAILED DATA(ls_failed_u)
       REPORTED DATA(ls_reported_u).

    ENDIF.

  ENDMETHOD.

  METHOD uploadData.

    DATA lv_attachment   TYPE xstring.

    DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lv_content      TYPE string,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lt_excel        TYPE STANDARD TABLE OF zbp_i_upload_list=>gty_gr_xl,
          lt_data         TYPE TABLE FOR CREATE zi_upload_list,
          lv_index        TYPE sy-index.

    FIELD-SYMBOLS: <lfs_col_header> TYPE string.

    lv_attachment = VALUE #( keys[ 1 ]-%param-FileBase64 OPTIONAL ).

    READ ENTITIES OF zi_upload_list IN LOCAL MODE
    ENTITY List
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_ulpoad_list).

    "Move Excel Data to Internal Table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
        iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select(
        lo_selection_pattern )->row_stream( )->operation->write_to(
            REF #( lt_excel ) ).
    lo_execute->set_value_transformation(
        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    " Get number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        "Implement error handling
    ENDTRY.

    IF lt_excel IS NOT INITIAL.
      "Validate Header record
      DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
      IF ls_excel IS NOT INITIAL.
        DO lv_no_of_cols TIMES.
          lv_index = sy-index.
          ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
          CHECK <lfs_col_header> IS ASSIGNED.
          DATA(lv_value) = to_upper( <lfs_col_header> ).
          DATA(lv_has_error) = abap_false.
          CASE lv_index.
            WHEN 1.
              lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
            WHEN 2.
              lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
            WHEN 3.
              lv_has_error = COND #( WHEN lv_value <> 'QUANTITY' THEN abap_true ELSE lv_has_error ).
            WHEN 4.
              lv_has_error = COND #( WHEN lv_value <> 'UOM' THEN abap_true ELSE lv_has_error ).
            WHEN 5.
              lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
            WHEN 6.
              lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
            WHEN 9. "More than 7 columns (error)
              lv_has_error = abap_true.
          ENDCASE.
          IF lv_has_error = abap_true.
            APPEND VALUE #( %tky = lt_ulpoad_list[ 1 ]-%tky ) TO failed-list.
            APPEND VALUE #(
              %tky = lt_ulpoad_list[ 1 ]-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'Wrong File Format!!' )
            ) TO reported-list.
            UNASSIGN <lfs_col_header>.
            EXIT.
          ENDIF.
          UNASSIGN <lfs_col_header>.
        ENDDO.
      ENDIF.
      CHECK lv_has_error = abap_false.

      DATA(lt_file_data) = lt_excel[].

      DELETE lt_file_data INDEX 1.

      DELETE lt_file_data WHERE po_number IS INITIAL.

      "Fill Line ID / Line Number

      LOOP AT lt_file_data ASSIGNING FIELD-SYMBOL(<lfs_excel>).

        TRY.
*          DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
            <lfs_excel>-line_id = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

*        <lfs_excel>-line_id     = lv_line_id.
        <lfs_excel>-line_number = sy-tabix.
      ENDLOOP.

      lt_data = VALUE #( FOR lwa_excel IN lt_file_data (
                                LineId          = lwa_excel-line_id
                         LineNum         = lwa_excel-line_number
                         PoNumber        = lwa_excel-po_number
                         PoItem          = lwa_excel-po_item
                         GrUantity      = lwa_excel-gr_quantity
                         UnitOfMeasure   = lwa_excel-unit_of_measure
                         SiteId          = lwa_excel-site_id
                         HeaderText      = lwa_excel-header_text
       ) ).

      "Delete Existing entry for user if any

      SELECT *
       FROM ztb_upload_list
       INTO TABLE @DATA(lt_LineId).

      DATA lt_del TYPE TABLE FOR DELETE zi_upload_list.

      lt_del = VALUE #( FOR x IN lt_LineId ( lineid = x-line_id LineNum = x-line_no ) ).

      IF lt_del IS NOT INITIAL.

        MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
         ENTITY List
         DELETE FROM lt_del
         FAILED   DATA(lt_failed)
         REPORTED DATA(lt_reported)
         MAPPED   DATA(lt_mapped).

      ENDIF.

      MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
       ENTITY List
       CREATE AUTO FILL CID FIELDS ( LineId LineNum PoNumber PoItem SiteId GrUantity UnitOfMeasure HeaderText )
       WITH lt_data
       MAPPED DATA(ls_mapped_u)
       FAILED DATA(ls_failed_u)
       REPORTED DATA(ls_reported_u).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
