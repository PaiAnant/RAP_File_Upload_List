@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view for upload file list'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity zi_upload_list
  as select from ztb_upload_list
{
  key line_id               as LineId,
  key line_no               as LineNum,
      po_number             as PoNumber,
      po_item               as PoItem,
      gr_uantity            as GrUantity,
      unit_of_measure       as UnitOfMeasure,
      site_id               as SiteId,
      header_text           as HeaderText,
//      attachment            as Attachment,
//      @Semantics.mimeType: true
//      mimetype              as Mimetype,
//      filename              as Filename,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt
}
