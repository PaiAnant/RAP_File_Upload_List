@EndUserText.label: 'Abstract entity for data upload'
define root abstract entity Z_I_UploadStream
{
  @UI.hidden : true
  FileName   : abap.char(255);
  @UI.hidden : true
  MimeType   : abap.char(128);

  @Semantics.largeObject.mimeType: 'MimeType'
  @Semantics.largeObject.fileName: 'FileName'
  @Semantics.largeObject.contentDispositionPreference: #INLINE
  @EndUserText.label: 'Select File to Upload'
  FileBase64 : abap.rawstring( 0 );

}
