CLASS lhc_List DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR List RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR List RESULT result.

    METHODS downloadTemplate FOR MODIFY
      IMPORTING keys FOR ACTION List~downloadTemplate.

ENDCLASS.

CLASS lhc_List IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD downloadTemplate.
  ENDMETHOD.

ENDCLASS.
