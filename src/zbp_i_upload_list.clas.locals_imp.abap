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

*    METHODS uploadData FOR MODIFY
*      IMPORTING keys FOR ACTION List~uploadData.

*    METHODS uploadData FOR MODIFY
*      IMPORTING keys FOR ACTION List~uploadData.

ENDCLASS.

CLASS lhc_List IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD downloadTemplate.
  ENDMETHOD.

*  METHOD uploadData.
*
*    DATA: lt_rows         TYPE STANDARD TABLE OF string,
*          lv_content      TYPE string,
*          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
*          lo_struct_descr TYPE REF TO cl_abap_structdescr,
*          lt_excel        TYPE STANDARD TABLE OF zbp_i_upload_list=>gty_gr_xl,
*          lt_data         TYPE TABLE FOR CREATE zi_upload_list,
*          lv_index        TYPE sy-index.
*
*    FIELD-SYMBOLS: <lfs_col_header> TYPE string.

*    READ ENTITIES OF zi_upload_list IN LOCAL MODE
*    ENTITY List
*    FIELDS ( Attachment Mimetype Filename )
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_ulpoad_list).
*
*    CHECK lt_ulpoad_list IS NOT INITIAL.
*
*    DATA(lv_attachment) = lt_ulpoad_list[ 1 ]-Attachment.
*
*    CHECK lv_attachment IS NOT INITIAL.
*
*    "Move Excel Data to Internal Table
*    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
*        iv_file_content = lv_attachment )->read_access( ).
*    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
*    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
*    DATA(lo_execute) = lo_worksheet->select(
*        lo_selection_pattern )->row_stream( )->operation->write_to(
*            REF #( lt_excel ) ).
*    lo_execute->set_value_transformation(
*        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).
*
*    " Get number of columns in upload file for validation
*    TRY.
*        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
*        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
*        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
*      CATCH cx_sy_move_cast_error.
*        "Implement error handling
*    ENDTRY.
*
*    IF lt_excel IS NOT INITIAL.
*      "Validate Header record
*      DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
*      IF ls_excel IS NOT INITIAL.
*        DO lv_no_of_cols TIMES.
*          lv_index = sy-index.
*          ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
*          CHECK <lfs_col_header> IS ASSIGNED.
*          DATA(lv_value) = to_upper( <lfs_col_header> ).
*          DATA(lv_has_error) = abap_false.
*          CASE lv_index.
*            WHEN 1.
*              lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
*            WHEN 2.
*              lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
*            WHEN 3.
*              lv_has_error = COND #( WHEN lv_value <> 'QUANTITY' THEN abap_true ELSE lv_has_error ).
*            WHEN 4.
*              lv_has_error = COND #( WHEN lv_value <> 'UOM' THEN abap_true ELSE lv_has_error ).
*            WHEN 5.
*              lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
*            WHEN 6.
*              lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
*            WHEN 9. "More than 7 columns (error)
*              lv_has_error = abap_true.
*          ENDCASE.
*          IF lv_has_error = abap_true.
*            APPEND VALUE #( %tky = lt_ulpoad_list[ 1 ]-%tky ) TO failed-list.
*            APPEND VALUE #(
*              %tky = lt_ulpoad_list[ 1 ]-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-error
*                       text     = 'Wrong File Format!!' )
*            ) TO reported-list.
*            UNASSIGN <lfs_col_header>.
*            EXIT.
*          ENDIF.
*          UNASSIGN <lfs_col_header>.
*        ENDDO.
*      ENDIF.
*      CHECK lv_has_error = abap_false.
*
*      DATA(lt_file_data) = lt_excel[].
*
*      DELETE lt_file_data INDEX 1.
*
*      DELETE lt_file_data WHERE po_number IS INITIAL.
*
*      "Fill Line ID / Line Number
*      TRY.
*          DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
*        CATCH cx_uuid_error.
*      ENDTRY.
*      LOOP AT lt_file_data ASSIGNING FIELD-SYMBOL(<lfs_excel>).
*        <lfs_excel>-line_id     = lv_line_id.
*        <lfs_excel>-line_number = sy-tabix.
*      ENDLOOP.

*      "Prepare Data for  Child Entity (XLData)
*      lt_data = VALUE #(
*          (   %cid_ref  = keys[ 1 ]-%cid_ref
*              %is_draft = keys[ 1 ]-%is_draft
*              EndUser   = keys[ 1 ]-EndUser
*              FileId    = keys[ 1 ]-FileId
*              %target   = VALUE #(
*                  FOR lwa_excel IN lt_file_data (
*                      "%cid        = |{ lwa_excel-po_number }_{ lwa_excel-po_item }_{ lwa_excel-site_id }|
*                      %cid         = keys[ 1 ]-%cid_ref
*                      %is_draft   = keys[ 1 ]-%is_draft
*                      %data = VALUE #(
*                          EndUser         = keys[ 1 ]-EndUser
*                          FileId          = keys[ 1 ]-FileId
*                          LineId          = lwa_excel-line_id
*                          LineNum         = lwa_excel-line_number
*                          PoNumber        = lwa_excel-po_number
*                          PoItem          = lwa_excel-po_item
*                          GrQuantity      = lwa_excel-gr_quantity
*                          UnitOfMeasure   = lwa_excel-unit_of_measure
*                          SiteId          = lwa_excel-site_id
*                          HeaderText      = lwa_excel-header_text
*                      )
*                      %control = VALUE #(
*                          EndUser         = if_abap_behv=>mk-on
*                          FileId          = if_abap_behv=>mk-on
*                          LineId          = if_abap_behv=>mk-on
*                          LineNum         = if_abap_behv=>mk-on
*                          PoNumber        = if_abap_behv=>mk-on
*                          PoItem          = if_abap_behv=>mk-on
*                          GrQuantity      = if_abap_behv=>mk-on
*                          UnitOfMeasure   = if_abap_behv=>mk-on
*                          SiteId          = if_abap_behv=>mk-on
*                          HeaderText      = if_abap_behv=>mk-on
*                      )
*                  )
*              )
*          )
*      ).

*      "Delete Existing entry for user if any
*      READ ENTITIES OF zi_file_user_ap IN LOCAL MODE
*      ENTITY FileUser BY \_FileData
*      ALL FIELDS WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_existing_XLData).
*      IF lt_existing_XLData IS NOT INITIAL.
*        MODIFY ENTITIES OF zi_file_user_ap IN LOCAL MODE
*        ENTITY FileData DELETE FROM VALUE #(
*          FOR lwa_data IN lt_existing_XLData (
*            %key        = lwa_data-%key
*            %is_draft   = lwa_data-%is_draft
*          )
*        )
*        MAPPED DATA(lt_del_mapped)
*        REPORTED DATA(lt_del_reported)
*        FAILED DATA(lt_del_failed).
*      ENDIF.

*      "Add New Entry for XLData (association)
*      MODIFY ENTITIES OF zi_file_user_ap IN LOCAL MODE
*      ENTITY FileUser CREATE BY \_FileData
*      AUTO FILL CID WITH lt_data.
*
*
*      "Modify Status
*      MODIFY ENTITIES OF zi_file_user_ap IN LOCAL MODE
*      ENTITY FileUser
*      UPDATE FROM VALUE #(  (
*          %tky        = lt_ulpoad_list[ 1 ]-%tky "keys[ 1 ]-%tky
*          FileStatus  = 'File Uploaded'
*          %control-FileStatus = if_abap_behv=>mk-on ) )
*      MAPPED DATA(lt_upd_mapped)
*      FAILED DATA(lt_upd_failed)
*      REPORTED DATA(lt_upd_reported).
*
*      "Read Updated Entry
*      READ ENTITIES OF zi_file_user_ap IN LOCAL MODE
*      ENTITY FileUser ALL FIELDS WITH CORRESPONDING #( Keys )
*      RESULT DATA(lt_updated_XLHead)
*
*      ENTITY FileData ALL FIELDS WITH CORRESPONDING #( Keys )
*      RESULT DATA(lt_updated_XLData).
*
*      "Send Status back to front end
*      result = VALUE #(
*        FOR lwa_upd_head IN lt_updated_XLHead (
*          %tky    = lwa_upd_head-%tky
*          %param  = lwa_upd_head
*        )
*      ).


*    ENDIF.
*
*  ENDMETHOD.

*  METHOD uploadData.
*
*    DATA: lt_rows         TYPE STANDARD TABLE OF string,
*          lv_content      TYPE string,
*          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
*          lo_struct_descr TYPE REF TO cl_abap_structdescr,
*          lt_excel        TYPE STANDARD TABLE OF zbp_i_upload_list=>gty_gr_xl,
*          lt_data         TYPE TABLE FOR CREATE zi_upload_list,
*          lv_index        TYPE sy-index.
*
*    FIELD-SYMBOLS: <lfs_col_header> TYPE string.
*
*    READ ENTITIES OF zi_upload_list IN LOCAL MODE
*    ENTITY List
*    FIELDS ( Attachment Mimetype Filename )
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_ulpoad_list).
*
*    CHECK lt_ulpoad_list IS NOT INITIAL.
*
*    DATA(lv_attachment) = lt_ulpoad_list[ 1 ]-Attachment.
*
*    CHECK lv_attachment IS NOT INITIAL.
*
*    "Move Excel Data to Internal Table
*    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
*        iv_file_content = lv_attachment )->read_access( ).
*    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
*    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
*    DATA(lo_execute) = lo_worksheet->select(
*        lo_selection_pattern )->row_stream( )->operation->write_to(
*            REF #( lt_excel ) ).
*    lo_execute->set_value_transformation(
*        xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).
*
*    " Get number of columns in upload file for validation
*    TRY.
*        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
*        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
*        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
*      CATCH cx_sy_move_cast_error.
*        "Implement error handling
*    ENDTRY.
*
*    IF lt_excel IS NOT INITIAL.
*      "Validate Header record
*      DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
*      IF ls_excel IS NOT INITIAL.
*        DO lv_no_of_cols TIMES.
*          lv_index = sy-index.
*          ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
*          CHECK <lfs_col_header> IS ASSIGNED.
*          DATA(lv_value) = to_upper( <lfs_col_header> ).
*          DATA(lv_has_error) = abap_false.
*          CASE lv_index.
*            WHEN 1.
*              lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
*            WHEN 2.
*              lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
*            WHEN 3.
*              lv_has_error = COND #( WHEN lv_value <> 'QUANTITY' THEN abap_true ELSE lv_has_error ).
*            WHEN 4.
*              lv_has_error = COND #( WHEN lv_value <> 'UOM' THEN abap_true ELSE lv_has_error ).
*            WHEN 5.
*              lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
*            WHEN 6.
*              lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
*            WHEN 9. "More than 7 columns (error)
*              lv_has_error = abap_true.
*          ENDCASE.
*          IF lv_has_error = abap_true.
*            APPEND VALUE #( %tky = lt_ulpoad_list[ 1 ]-%tky ) TO failed-list.
*            APPEND VALUE #(
*              %tky = lt_ulpoad_list[ 1 ]-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-error
*                       text     = 'Wrong File Format!!' )
*            ) TO reported-list.
*            UNASSIGN <lfs_col_header>.
*            EXIT.
*          ENDIF.
*          UNASSIGN <lfs_col_header>.
*        ENDDO.
*      ENDIF.
*      CHECK lv_has_error = abap_false.
*
*      DATA(lt_file_data) = lt_excel[].
*
*      DELETE lt_file_data INDEX 1.
*
*      DELETE lt_file_data WHERE po_number IS INITIAL.
*
*      "Fill Line ID / Line Number
*      TRY.
*          DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
*        CATCH cx_uuid_error.
*      ENDTRY.
*      LOOP AT lt_file_data ASSIGNING FIELD-SYMBOL(<lfs_excel>).
*        <lfs_excel>-line_id     = lv_line_id.
*        <lfs_excel>-line_number = sy-tabix.
*      ENDLOOP.
*
*    ENDIF.
*
*  ENDMETHOD.

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
      TRY.
          DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
      ENDTRY.
      LOOP AT lt_file_data ASSIGNING FIELD-SYMBOL(<lfs_excel>).
        <lfs_excel>-line_id     = lv_line_id.
        <lfs_excel>-line_number = sy-tabix.
      ENDLOOP.

*      lt_data = CORRESPONDING #( lt_file_data ).

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

      SELECT line_id
       FROM ztb_upload_list
       INTO TABLE @DATA(lt_LineId).

      DATA lt_del TYPE TABLE FOR DELETE zi_upload_list.

      lt_del = VALUE #( FOR x IN lt_LineId ( lineid = x-line_id ) ).

*      MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
*       ENTITY List
*       DELETE FROM lt_del
*       FAILED   DATA(lt_failed)
*       REPORTED DATA(lt_reported)
*       MAPPED   DATA(lt_mapped).


      MODIFY ENTITIES OF zi_upload_list IN LOCAL MODE
       ENTITY List
       CREATE AUTO FILL CID
       WITH lt_data
       MAPPED DATA(ls_mapped_u)
       FAILED DATA(ls_failed_u)
       REPORTED DATA(ls_reported_u).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
