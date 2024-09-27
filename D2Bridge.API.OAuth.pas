//    João B. S. Junior
//   (69) 9 9250-3445
//   jr.playsoft@gmail.com

unit D2Bridge.API.OAuth;

interface

uses
  IdURI,
  REST.Utils,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.JSON,
  System.SysUtils,
  System.Classes,
  D2Bridge.Instance,
  Prism.Session;


type
  TD2BridgeAPIOAuth = class
    private
        FCallback,
        FRedirect_URI,
        FClient_ID,
        FClient_Secret,
        FScope,

        FUserID,
        FUserName,
        FUserEmail,
        FUserPicture,
        FUserPictureHTML: String;

    public

       constructor Create;

       property  Callback: String read FCallback write FCallback;
       property  Redirect_URI: String read FRedirect_URI write FRedirect_URI;
       property  Client_ID: String read FClient_ID write FClient_ID;
       property  Client_Secret: String read FClient_Secret write FClient_Secret;
       property  Scope: String read FScope write FScope;

       property  UserID: String read FUserID write FUserID; //ID do Usuário no google
       property  UserName: String read FUserName write FUserName; //Nome do Usuário no google
       property  UserEmail: String read FUserEmail write FUserEmail; //Email do Usuário no google
       property  UserPicture: String read FUserPicture write FUserPicture; //URL da Foto do Usuário no google caso tenha preenchido
       property  UserPictureHTML: String read FUserPictureHTML write FUserPictureHTML; //URL da Foto do Usuário no google caso tenha preenchido


       procedure Redirect(URL:string; newpage:Boolean = false);
       procedure LoginStart;
       function  LoginVerify:Boolean;
       procedure Logout;

end;

implementation

constructor TD2BridgeAPIOAuth.Create;
begin
     Redirect_URI  := 'http://localhost:8077';
     Callback      := 'oauth2callback=google';
     Client_ID     := '73318356842-34d31m8kg2b69vv4c6lignu78bgejjbv.apps.googleusercontent.com';
     Client_Secret := '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';
     Scope         := 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';
end;

procedure TD2BridgeAPIOAuth.Redirect(URL:string; newpage:Boolean = false);
var
    js:string;
begin

    {$REGION 'docs'}
      {
        -------
        newpage
               o método 'window.open' redireciona o usuario para uma nova aba / janela do navegador mantendo a anteior.
               'newpage' nao é usado em conjunto com 'cleanhistory' uma vez que ao abrir uma nova aba/janela ele não modifica a janela anterior.

               The window.open method redirects the user to a new tab/window of the browser while keeping the previous one.
               'newpage' is not used in conjunction with 'cleanhistory' since opening a new tab/window does not modify the previous window.
        ------------


         By João B. S. Junior 09-06-2024
      }
      {$ENDREGION}

    if newpage then
         js:='window.open('+QuotedStr(URL)+','+QuotedStr('_blank')+');'
        else
           js:=' window.location.assign('+QuotedStr(URL)+');';

    PrismSession.ExecJS(js);
end;

procedure TD2BridgeAPIOAuth.LoginStart;
var
      vURI,
      URL:string;

begin
      // Criamos aqui a URL para chamar a página de login do Google.
      // Isso redirecionará de volta para nossa aplicação onde poderemos verificar quem está logado

      vURI:=FRedirect_URI+'/?'+FCallback;

      URL := 'https://accounts.google.com/o/oauth2/auth';
      URL := URL + '?response_type=' + URIEncode('code');
      URL := URL + '&client_id='     + URIEncode(FClient_ID);
      URL := URL + '&redirect_uri='  + URIEncode(vURI);
      URL := URL + '&scope='         + URIEncode(FScope);

      Redirect(URL,false);
end;



function TD2BridgeAPIOAuth.LoginVerify:boolean;
var
    vCallBack,
    AuthCode,
    token     : string;
    vHttp     : TNetHTTPClient;
    vParams   : Tstringlist;
    vResponse : IHTTPresponse;

    ResponseJSON: TJSONObject;
begin
  Result:=False;

  if PrismSession.URI.QueryParams.Items.Count > 0 then
  begin
     if PrismSession.URI.QueryParams.Items[0].Key ='oauth2callback' then
     begin
        vCallBack := TIdURI.URLDecode(PrismSession.URI.QueryParams.Items[0].Value);
        AuthCode :=  TIdURI.URLDecode(PrismSession.URI.QueryParams.Items[1].Value);
     end;
  end;

  if (AuthCode<>'') and (vCallBack='google') then
  begin
      try
         try
              vHttp := TNetHTTPClient.Create(nil);
              vParams := Tstringlist.Create;
              vParams.Add('code=' + AuthCode);
              vParams.Add('client_id=' + Client_ID);
              vParams.Add('client_secret='+ Client_secret);
              vParams.Add('redirect_uri=' + Redirect_uri+'/?'+Callback);
              vParams.Add('grant_type=authorization_code');

              vResponse := vhttp.Post('https://oauth2.googleapis.com/token', vParams);

              if vResponse.StatusText='OK' then
              begin
                 Try
                    ResponseJSON := TJSONObject.ParseJSONValue(vResponse.ContentAsString) as TJSONObject;
                    token :=  ResponseJSON.GetValue<string>('access_token');
                 finally
                    ResponseJSON.Free;
                 End;
              end
              else exit;

              // obtivemos o token de acesso, então agora podemos saber quem está logado!
              vparams.Clear;
              vparams.Add('access_token=' + token);
              vResponse := vhttp.get ('https://www.googleapis.com/oauth2/v2/userinfo?'+'access_token=' + token);
              if vResponse.StatusText='OK' then
              begin
                      ResponseJSON := TJSONObject.ParseJSONValue(vResponse.ContentAsString) as TJSONObject;
                      try
                          UserEmail   := ResponseJSON.GetValue<string>('email');
                          UserName    := ResponseJSON.GetValue<string>('name');
                          UserPicture := ResponseJSON.GetValue<string>('picture');
                          UserPictureHTML:='<img class="rounded float-left img-fluid" style="" id="GOOGLE_PICTURE_PERFIL" src="'+UserPicture+
                                           '">';
                      finally
                         ResponseJSON.Free;
                      end;
                      Result:=true;
              end;
         Except
               on E : exception do
                 Result:=false;
         end;

      finally
          vhttp.Free;
          vparams.Free;
      end;

  end;  // Fim do callback do google

end;

procedure TD2BridgeAPIOAuth.Logout;
begin
    Redirect('https://mail.google.com/mail/u/0/?logout&hl=ptBR',true);
end;



end.
