\NeedsTeXFormat{LaTeX2e}
\RequirePackage[utf8]{inputenc}
\ProvidesClass{ppges}[2026/03/08]

\newif\ifppgesenglish
\DeclareOption{english}{\ppgesenglishtrue}
\DeclareOption{brazilian}{\ppgesenglishfalse}
\ExecuteOptions{brazilian}
\ProcessOptions\relax

\LoadClass[11pt,a4paper]{report}

\ifppgesenglish
	\PassOptionsToPackage{english}{babel}
\else
	\PassOptionsToPackage{brazilian}{babel}
\fi

\newcommand{\ppgesenglishmonth}[1]{%
	\ifcase#1\or January\or February\or March\or April\or May\or June\or July\or August\or September\or October\or November\or December\fi}
\newcommand{\ppgesbrazilianmonth}[1]{%
	\ifcase#1\or janeiro\or fevereiro\or março\or abril\or maio\or junho\or julho\or agosto\or setembro\or outubro\or novembro\or dezembro\fi}

\ifppgesenglish
	\newcommand{\ppgescovertext}{Master's Dissertation submitted to the Graduate Program in Energy and Society, Celso Suckow da Fonseca Federal Center for Technological Education (CEFET/RJ), as partial fulfillment of the requirements for the master's degree.}
	\newcommand{\ppgesadvisorlabel}{Advisors:}
	\newcommand{\ppgessignaturetext}{Master's Dissertation in Energy and Society, Celso Suckow da Fonseca Federal Center for Technological Education (CEFET/RJ).}
	\newcommand{\ppgesapprovedlabel}{Approved by:}
	\newcommand{\ppgesacrtitle}{LIST OF ACRONYMS}
	\newcommand{\ppgestodaycover}{\ppgesenglishmonth{\month}\space\number\day, \number\year}
\else
	\newcommand{\ppgescovertext}{Dissertação de Mestrado apresentada ao Programa de Pós-graduação em Energia e Sociedade, Centro Federal de Educação Tecnológica Celso Suckow da Fonseca CEFET/RJ, como parte dos requisitos necessários à obtenção do grau de mestre.}
	\newcommand{\ppgesadvisorlabel}{Orientadores:}
	\newcommand{\ppgessignaturetext}{Dissertação de Mestrado em Energia e Sociedade, Centro Federal de Educação Tecnológica Celso Suckow da Fonseca, CEFET/RJ.}
	\newcommand{\ppgesapprovedlabel}{Aprovada por:}
	\newcommand{\ppgesacrtitle}{LISTA DE ACRÔNIMOS}
	\newcommand{\ppgestodaycover}{\number\day\space de \ppgesbrazilianmonth{\month}\space de \number\year}
\fi

%% Load additional packages and commands.
\RequirePackage[a4paper, left=2.5cm, right=2cm, top=2.5cm, bottom=2cm]{geometry} 
\RequirePackage[square,authoryear]{natbib}
\RequirePackage{babel}
\RequirePackage[dvipsnames,svgnames,table]{xcolor}
\RequirePackage{amsmath}
\RequirePackage{booktabs}
\RequirePackage{colortbl}
\RequirePackage{tracklang}
\TrackLangShowWarningsfalse
\RequirePackage[acronym,nomain]{glossaries}
\TrackLangShowWarningstrue
%\RequirePackage{datagidx}
%\usepackage{epstopdf}
\RequirePackage{fancyhdr} 
\RequirePackage{float} 
\RequirePackage{framed}
\RequirePackage{graphicx} 
\RequirePackage{helvet}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage{indentfirst}
%\RequirePackage{makeidx}
\RequirePackage{multicol}
\RequirePackage{multirow}
\RequirePackage{ragged2e}
\RequirePackage{setspace}
\RequirePackage{titlesec}
\RequirePackage{tocloft}
\RequirePackage{wrapfig} 
\RequirePackage{xcolor}
\RequirePackage{subfig}
\RequirePackage{algorithm}
\RequirePackage{amssymb}
\RequirePackage{algpseudocode,algorithm}
\RequirePackage{pdfpages}

%% Additional TeX/LaTeX code...

\linespread{1.5} 

\setlength\parindent{1.25cm} 

% Numeracao Pagina
\pagestyle{fancy}
\fancyhf{}
\fancyheadoffset{0cm}
\renewcommand{\headrulewidth}{0pt} 
\renewcommand{\footrulewidth}{0pt}
\fancyhead[R]{\thepage}
\fancypagestyle{plain}{%
	\fancyhf{}%
	\fancyhead[R]{\thepage}%
}
\setlength{\headheight}{14pt}
\addtolength{\topmargin}{-2pt}

% Numeracao capitulos em romano
\renewcommand{\thechapter}{\Roman{chapter}}
\AtBeginDocument{%
	\@ifundefined{captionsenglish}{}{%
		\addto\captionsenglish{%
			\renewcommand{\chaptername}{Chapter}%
			\renewcommand{\contentsname}{CONTENTS}%
			\renewcommand{\listfigurename}{LIST OF FIGURES}%
			\renewcommand{\listtablename}{LIST OF TABLES}%
			\renewcommand{\figurename}{Figure}%
			\renewcommand{\tablename}{Table}%
		}%
	}%
	\@ifundefined{captionsbrazilian}{}{%
		\addto\captionsbrazilian{%
			\renewcommand{\chaptername}{Capítulo}%
			\renewcommand{\contentsname}{SUMÁRIO}%
			\renewcommand{\listfigurename}{LISTA DE FIGURAS}%
			\renewcommand{\listtablename}{LISTA DE TABELAS}%
			\renewcommand{\figurename}{Figura}%
			\renewcommand{\tablename}{Tabela}%
		}%
	}%
	\ifppgesenglish
		\renewcommand{\chaptername}{Chapter}%
		\renewcommand{\contentsname}{CONTENTS}%
		\renewcommand{\listfigurename}{LIST OF FIGURES}%
		\renewcommand{\listtablename}{LIST OF TABLES}%
		\renewcommand{\figurename}{Figure}%
		\renewcommand{\tablename}{Table}%
		\@ifundefined{selectlanguage}{}{\selectlanguage{english}}%
	\else
		\renewcommand{\chaptername}{Capítulo}%
		\renewcommand{\contentsname}{SUMÁRIO}%
		\renewcommand{\listfigurename}{LISTA DE FIGURAS}%
		\renewcommand{\listtablename}{LISTA DE TABELAS}%
		\renewcommand{\figurename}{Figura}%
		\renewcommand{\tablename}{Tabela}%
		\@ifundefined{selectlanguage}{}{\selectlanguage{brazilian}}%
	\fi
}
\titleformat{\chapter}[hang] 
{\normalfont\large\bfseries\centering}{\chaptertitlename\ \thechapter }{1em}{}
\titleformat{\section}[hang]
{\normalfont\normalsize\bfseries\raggedright}{\thesection}{1em}{}
\titleformat{\subsection}[hang]
{\normalfont\normalsize\bfseries\raggedright}{\thesubsection}{1em}{}

% centraliza Sumario
\renewcommand{\cfttoctitlefont}{\hfill\large\bfseries} 
\renewcommand{\cftaftertoctitle}{\hfill}
\setlength{\cftchapnumwidth}{3.2em}
\setlength{\cftsecnumwidth}{4.2em}
\setlength{\cftsubsecnumwidth}{5.0em}

% Centraliza Lista de Tabelas
\renewcommand{\cftlottitlefont}{\hfill\bfseries\large} 
\renewcommand{\cftafterlottitle}{\hfill}

% Centraliza Lista de Figuras
\renewcommand{\cftloftitlefont}{\hfill\bfseries\large} 
\renewcommand{\cftafterloftitle}{\hfill}

\newcolumntype{L}[1]{>{\raggedright\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{C}[1]{>{\centering\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{R}[1]{>{\raggedleft\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}

\newcommand\Tstrut{\rule{0pt}{2.6ex}} % = `top' strut
\newcommand\Bstrut{\rule[-0.9ex]{0pt}{0pt}} % = `bottom' strut
\newcommand{\specialcell}[2][c]{%
	\begin{tabular}[#1]{@{}c@{}}#2\end{tabular}}

%\newgidx{acronym}{Lista de Acrônimos}
%\DTLgidxSetDefaultDB{acronym}

%dcover
\newcommand\dcover{
	\begin{titlepage}
		
		\newgeometry{left=2.5cm, right=2.5cm, top=2cm, bottom=2cm}
		\center 
		
		\begin{flushleft}
			\includegraphics[scale=0.8]{logocefet.jpg}\\[2cm]
		\end{flushleft}
		
		\begin{minipage}{\textwidth}
			\begin{center}
				{\large \MakeUppercase{\dtitle}}\\[0.7cm]
				{\large \dauthor}
			\end{center}
		\end{minipage}\\[0.7cm]
		
		\begin{flushright}
			\begin{minipage}{0.5\textwidth}
				\normalsize
				\singlespacing
				\ppgescovertext
			\end{minipage}\\[1.5cm]
		\end{flushright}
		
		\begin{flushright}
			\begin{minipage}{0.5\textwidth}
				\normalsize
				\singlespacing
				\ppgesadvisorlabel \\
				\dadvisor
			\end{minipage}\\
		\end{flushright}
		\vfill	
		Rio de Janeiro,\\
		\ppgestodaycover
		
	\end{titlepage}
}


\newcommand\dsignatures{
	\thispagestyle{empty} 
	
	\newcommand{\HRule}{\rule{0.6\linewidth}{0.5mm}}
	\center 
	
	\begin{minipage}{0.9\textwidth}
		\begin{center}
			{\bfseries \large \dtitle}\\[0.7cm]
		\end{center}
	\end{minipage}\\[3cm]
	
	\begin{minipage}{0.9\textwidth}
		\normalsize
		\ppgessignaturetext
	\end{minipage}\\[2cm]
	
	\begin{minipage}{0.9\textwidth}
		\begin{center}
			\dauthor
		\end{center} 
	\end{minipage}\\[2cm]
	
	\begin{minipage}{0.9\textwidth}
		\begin{flushleft}
			\ppgesapprovedlabel
		\end{flushleft}
	\end{minipage}\\[1cm]
	
	\center
	
	\djury
	
	\vfill	
	Rio de Janeiro,\\
	\ppgestodaycover
}

%dlibrary
\newcommand{\dlibrary}[1]{
	\includepdf{#1} 
%	\center
	\vfill	
%	\pagebreak
}

%ddedicatory
\newcommand{\ddedicatory}[1]{
\chapter*{DEDICATÓRIA}
	%\thispagestyle{empty}
	\vspace*{15em}%
	\begin{flushright}
		\begin{minipage}{0.5\textwidth}
			#1
		\end{minipage}\\[1.5cm]
	\end{flushright}
	\pagebreak
}

%ddedicatory
\newcommand{\dacknowledgment}[1]{
	
\chapter*{AGRADECIMENTOS}
%\thispagestyle{empty}
\vspace*{10em}%
\begin{flushright}
	\begin{minipage}{0.5\textwidth}
		#1
	\end{minipage}\\[1.5cm]
\end{flushright}

\pagebreak
}

%dresumo
\newcommand{\dresumo}[2]{
\begin{otherlanguage*}{brazilian}
\chapter*{RESUMO}


\begin{center}
	\large \dtitle \\[0.5cm]% Title of your document
	\dauthor\\[0.3cm]
\end{center}

\begin{singlespacing}
	\begin{minipage}{0.9\textwidth}
		Orientadores: \\
		\dadvisor
	\end{minipage}\\[0.3cm]
	
	\begin{center}
		\begin{minipage}{0.9\textwidth}\small
			Resumo da Dissertação submetida ao Programa de Pós-graduação em Energia e Sociedade do Centro Federal de Educação Tecnológica Celso Suckow da Fonseca CEFET/RJ como parte dos requisitos necessários à obtenção do grau de mestre.
		\end{minipage}\\[0.3cm]
	\end{center}
	
	\justifying
	
	#1
	\par
	\noindent Palavras-chave: #2
	
\end{singlespacing}

\vspace{1cm}
\vfill
\begin{center}
	Rio de Janeiro,\\
	\number\day\space de \ppgesbrazilianmonth{\month}\space de \number\year
\end{center}
\end{otherlanguage*}
}

%dabstract
\newcommand{\dabstract}[2]{
\begin{otherlanguage*}{english}
	\chapter*{ABSTRACT}
	
	\begin{center}
		\large \dtitle \\[0.5cm]% Title of your document
		\dauthor\\[0.3cm]
	\end{center}
	
	\begin{singlespacing}
		\begin{minipage}{0.9\textwidth}
			Advisors: \\
			\dadvisor
		\end{minipage}\\[0.3cm]
		
		\begin{center}
			\begin{minipage}{0.9\textwidth}\small
				Abstract of dissertation submitted to Programa de Pós-graduação em Energia e Sociedade - Centro Federal de Educação Tecnológica Celso Suckow da Fonseca CEFET/RJ as partial fulfillment of the requirements for the degree of master.
			\end{minipage}\\[0.3cm]
		\end{center}
		
		
		\justifying
		
		#1
		\par
		\noindent Keywords: #2
		
		
	\end{singlespacing}
	
	\vspace{1cm}
	\vfill
	\begin{center}
		Rio de Janeiro,\\
		\ppgesenglishmonth{\month}\space\number\day, \number\year 
	\end{center}
	\pagebreak
\end{otherlanguage*}
}

%dtables
\newcommand{\dtables}{
\ifppgesenglish
\selectlanguage{english}
\else
\selectlanguage{brazilian}
\fi

%\renewcommand{\backrefpagesname}{Citado na(s) página(s):~}
%\renewcommand{\backref}{}
	
\renewcommand{\cftdot}{}
\tableofcontents
\pagebreak

\listoffigures
\pagebreak

\listoftables
\pagebreak

%\printterms[database=acronym,columns=1,prelocation=hfill,style=align]
%\label{lastpretextualpage}
%\pagebreak
\clearpage
\renewcommand{\glossarysection}[2][]{}
{\large\selectfont \centerline{\textbf{\ppgesacrtitle}} \vskip12pt\par}
\setlength{\LTleft}{0pt}
\printglossary[type=\acronymtype,style=long,nonumberlist]
\pagebreak


}





\endinput
