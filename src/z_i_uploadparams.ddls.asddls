@EndUserText.label: 'Abstract entity for upload parameters'
define root abstract entity Z_I_UploadParams

{
  // Dummy is a dummy field
  @UI.hidden        : true
  dummy             : abap_boolean;
  _StreamProperties : association [1] to Z_I_UploadStream on 1 = 1;

}
