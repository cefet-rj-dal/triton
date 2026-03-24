\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ppges}[2026/03/08]

\LoadClass[11pt,a4paper]{report}

%% Load additional packages and commands.
\RequirePackage[a4paper, left=2.5cm, right=2cm, top=2.5cm, bottom=2cm]{geometry} 
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage[square,authoryear]{natbib}
\RequirePackage[dvipsnames,svgnames,table]{xcolor}
\RequirePackage{amsmath}
\RequirePackage{booktabs}
\RequirePackage{colortbl}
\RequirePackage[acronym,nomain]{glossaries}
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
\renewcommand{\chaptername}{Capítulo}
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

%\newgidx{acronym}{Lista de Abreviações}
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
				Dissertação de Mestrado apresentada ao Programa de Pós-graduação em Energia e Sociedade, Centro Federal de Educação Tecnológica Celso Suckow da Fonseca CEFET/RJ, como parte dos requisitos necessários à obtenção do grau de mestre.
			\end{minipage}\\[1.5cm]
		\end{flushright}
		
		\begin{flushright}
			\begin{minipage}{0.5\textwidth}
				\normalsize
				\singlespacing
				Orientadores: \\
				\dadvisor
			\end{minipage}\\
		\end{flushright}
		\vfill	
		Rio de Janeiro,\\
		\today
		
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
		Dissertação de Mestrado em Energia e Sociedade, Centro Federal de Educação Tecnológica Celso Suckow da Fonseca, CEFET/RJ. 
	\end{minipage}\\[2cm]
	
	\begin{minipage}{0.9\textwidth}
		\begin{center}
			\dauthor
		\end{center} 
	\end{minipage}\\[2cm]
	
	\begin{minipage}{0.9\textwidth}
		\begin{flushleft}
			Aprovada por:
		\end{flushleft}
	\end{minipage}\\[1cm]
	
	\center
	
	\djury
	
	\vfill	
	Rio de Janeiro,\\
	\today
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

\centering
\vfill	
Rio de Janeiro,\\
\today
}

%dabstract
\newcommand{\dabstract}[2]{
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
		\today 
	\end{center}
	\pagebreak
}

%dtables
\newcommand{\dtables}{

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
{\fontsize{12pt}{\baselineskip}\selectfont \centerline{ \textbf{Lista de Acrônimos}} \vskip12pt\par}	
\setlength{\LTleft}{0pt}
\printglossary[type=\acronymtype,style=long,nonumberlist]
\pagebreak


}





\endinput
