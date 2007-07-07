% Visualization of quality of approximation of X given principal comp.
%
% X can either represent a single element (a single image or video), or a
% set of elements. In the latter case, index controls which element of X to
% apply visualization to, if unspecified it is chosen randomly.
%
% USAGE
%  varargout=pca_visualize(U, mu, vars, X, [index], [ks], [fname], [show])
%
% INPUTS
%  U           - returned by pca.m
%  mu          - returned by pca.m
%  vars        - returned by pca.m
%  X           - Set of images or videos, or a single image or video
%  index       - [] controls which element of X to aplply visualization to
%  ks          - [] ks values of k for pca_apply (ex. ks=[1 4 8 16])
%  fname       - [] if specified outputs avis
%  show        - [] will display results in figure(show) and figure(show+1)
%
% OUTPUTS
%  M           - [only if X is a movie] movie of xhats (see pcaapply)
%  MDiff       - [only if X is a movie] movie of difference images
%  MU          - [only if X is a movie] movie of eigenmovies
%
% EXAMPLE
%
% See also PCA, PCA_APPLY

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout=pca_visualize( U, mu, vars, X, index, ks, fname, show )

siz = size(X); nd = ndims(X);  [N,r]  = size(U);
if(N==prod(siz) && ~(nd==2 && siz(2)==1)); siz=[siz, 1]; nd=nd+1; end
fsiz = siz(1:end-1); d = prod(fsiz);
inds = {':'}; inds = inds(:,ones(1,nd-1));

if( d~=N ); error('incorrect size for X or U'); end
if( nargin<5 || isempty(index) ); index = 1+randint(1,1,siz(end)); end
if( index>siz(end) ); error(['index >' num2str(siz(end))]); end
if( nargin<6 || isempty(ks) ); maxp=floor(log2(r)); ks=2.^(0:maxp); end
if( nargin<7 || isempty(fname)); fname = []; end
if( nargin<8 || isempty(show)); show = 1; end

%%% create xhats image of PCA reconstruction
ks = ks( ks<=r );
x = double( X(inds{:},index) );
xhats = x;  diffs = []; errors = zeros(1,length(ks));
for k=1:length(ks)
  [ Yk, xhat, errors(k) ] = pca_apply( x, U, mu, ks(k) );
  xhats = cat( nd, xhats, xhat );
  diffs = cat( nd, diffs, (xhat-x).^2 );
end

%%% calculate residual at each k for plot purposes
residuals = vars / sum(vars);
residuals = 1-cumsum(residuals);
residuals = [1; residuals(1:max(ks))];

%%% show decay image
figure(show); clf;
plot(  0:max(ks), residuals, 'r- .',  ks, errors, 'g- .' );
hold('on'); line( [0,max(ks)], [.1,.1] ); hold('off');
title('error of approximation vs number of eigenbases used');
legend('residuals','errors - actual');

%%% reshape U to have first dimensions same as x
k = min(100,r);  st=0;
Uim = reshape( U(:,1+st:k+st), [ fsiz k ]  );

%%% visualization
labels=cell(1,length(ks));
for k=1:length(ks); labels{k} = ['k=' num2str(ks(k))]; end
if( nd==3 ) % images
  figure(show+1); clf;
  subplot(2,2,1); montage2( Uim, 1,0 ); title('principal components');
  subplot(2,2,2); im( mu ); title('mean');
  subplot(2,2,3); montage2(xhats,1,0,[],[],[],{'original' labels{:}} );
  title('various approximations of x');
  subplot(2,2,4); montage2( diffs, 1, 0, [], [], [], labels );
  title('difference images');
  if (~isempty(fname))
    print( [fname '_eigenanalysis.jpg'], '-djpeg' );
  end

elseif( nd==4 ) % videos
  %%% create movies
  if( nargout>0 ); figureresized(.6,show+1); clf;
    M = makemovies( xhats, {0, [], [], 0, {'original' labels{:}}} );
    varargout={M};
  end;
  if( nargout>1 ); figureresized(.6,show+1); clf;
    MDiff = makemovies( diffs, {0, [], [], 0, labels} );
    varargout{2} = MDiff;
  end;
  if( nargout>2 ); figureresized(.6,show+1); clf;
    MU = makemovies( Uim );
    varargout{3} = MU;
  end;

  %%% optionally record image and movie
  if (~isempty(fname))
    print( [fname '_decay.jpg'], '-djpeg' );
    compr = { 'Compresion', 'Cinepak' };
    if( nargout>0 ); movie2avi(M, [fname '.avi'], compr{:} ); end
    if( nargout>1 ); movie2avi(MDiff,[fname '_diff.avi'],compr{:} ); end;
    if( nargout>2 ); movie2avi(MU,'prineigenimages.avi',compr{:} ); end;
  end
end
