@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view for ZI_UPLOAD_LIST'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_UPLOAD_LIST
  provider contract transactional_query
  as projection on zi_upload_list
{
  key LineId,
  key LineNum,
      PoNumber,
      PoItem,
      GrUantity,
      UnitOfMeasure,
      SiteId,
      HeaderText,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt
}
