# Carregar os pacotes necess�rios para realizar os c�lculos
library(lifecontingencies)
library(tidyverse)

setwd("") # selecionar a pasta com o arquivo

# Importar a t�bua de mortalidade
at2000 <- read.table("at2000.txt", header = TRUE)
head(at2000) 

x <- as.numeric(at2000$x)
lx <- as.numeric(at2000$lx)
class(x)
class(lx)

# Criar a t�bua atuarial com a comuta��o com juros a 6%
tabua <- new("actuarialtable", x = x, lx = lx, interest = 0.06)
tabua

# Premissas
i <- 0.06
cs <- 0.01
Br <- 60000
sy <- 48000
y <- 20
x <- 30
r <- 65
med_n <- 10
ar <- axn(tabua, x = r, i = i)
ar
ay_r <- axn(tabua, x = y, n = r - y,i = i)
ay_r

# Fun��o sal�rio
sal�rio <- function(s, cs, n){
  calc <- s * (1 + cs)^n
  return(calc)
  }

sal�rio(1000, 0.01, 15)

sr <- sal�rio(s = sy, cs = cs, n = r - y)
sr

# Fun��o para criar o vetor dos sal�rios

vetor_sal�rio <- function(s_inicial, cres_sal, tempo){
  
  t <- tempo
  sal <- 0
  if(t == 0){
    sal[1] <- s_inicial
    return(sal)
  }else if(t == 1){
    sal[1] <- s_inicial
    sal[2] <- s_inicial*(1+cres_sal)
    return(sal)
  } else if (t == 2){
    sal[1] <- s_inicial
    sal[2] <- s_inicial*(1+cres_sal)
    sal[3] <- s_inicial*(1+cres_sal)^2
    return(sal)
    } else{
      sal[1] <- s_inicial
      sal[2] <- s_inicial*(1+cres_sal)
      sal[3] <- s_inicial*(1+cres_sal)^2
    cont <- 3
      for(s in 4:(t+1)){
        sal[s] <- sal�rio(s_inicial, cres_sal, cont)
        cont <- cont + 1
  }
    return(sal)
}
}
sal�rios <- vetor_sal�rio(sy, cs, r - y)
sal�rios

sum(sal�rios[1:(r-y)])

vetor_sal�rio(sy, cs, 0)
vetor_sal�rio(sy, cs, 1)
vetor_sal�rio(sy, cs, 2)
vetor_sal�rio(sy, cs, 3)
vetor_sal�rio(sy, cs, 4)
vetor_sal�rio(sy, cs, 5)

qplot(x = seq(y:r), y  = sal�rios, xlab = "idade", main = "Sal�rios")


# Fun��o v (desconto financeiro)
d_fin <- function(i, n){
  return((1/(1+i)^n))
}

d_fin(i = i, n = r - x)

# Fun��o para criar o vetor com os descontos financeiros de y at� r

vetor_desconto <- function(i, tempo){
  t <- tempo
  d <- rep(0, t)
  d[1] <- d_fin(i = i, n = t)
  
  for(u in 2:(t+1)){
    d[u] <- d_fin(i, tempo - u + 1)
  }
  return(d)
}

desconto <- vetor_desconto(i, r - y)
desconto
qplot(x = seq(y:r), y = desconto, xlab = "tempo", main = "Desconto Financeiro")

# Fun��o probabilidade de y at� x
pxt(tabua, x = y, t = r - y)

rpy <- function(tabua, idade, tempo){

  t <- tempo
  probs <- rep(0, t)
  probs[1] <- pxt(tabua, idade, t)
 
   for(z in 2:(t+1)){
    
    probs[z] <- pxt(tabua, x = idade + z - 1, t = t - z + 1)  

  }
  return(probs)
}

# Criar o vetor com as probabilidades
probabilidade <- rpy(tabua, idade = y, tempo = r-y)
probabilidade

pxt(tabua, 64, 1)

# Criar o vetor do p*v*ar

pvar <- probabilidade * desconto * ar
pvar

# Criar a coluna do VABF

VPBF <- Br*pvar
VPBF

# Criar a coluna dos 'x'
x <- seq(20, 65, 1)

# Juntar a coluna dos 'x', das probabilidades, do desconto e dos sal�rios
da <- cbind(x, probabilidade, desconto, pvar, VPBF, sal�rios)

# visualizar
da

# M�TODOS DE FINANCIAMENTO

# 1. uc - valor constante

# c�lculo do bx
bx1 <- Br/(r - y)
bx1
qplot(x = x,y = bx1, main = "bx para Unidade de Cr�dito - Valor Constante")

# c�lculo do Bx
Bx <- function(bx, n){
  B <- rep(0, n+1)
  
  for(a in 2:(n+1)){
    B[a] <- B[a-1] + bx
  }
  return(B)
}

Bacum1 <- Bx(bx1, r - y)
Bacum1
qplot(x=x,y=Bacum1, main = "Bx")

# C�lculo do Custo Normal - CN = bx * pvar
cn1 <- bx1 * pvar[1:(r-y)]
cn1
qplot(x=x[seq(1:45)], y=cn1, xlab = "idade")
length(cn1)

# C�lculo do ALx - passivo atuarial - Bx*pvar
ALx <- Bacum1 * pvar
ALx
qplot(x=x, y=ALx)

# C�lculo da al�quota
aliquota1 <- (cn1 / sal�rios[1:(r-y)]) * 100
aliquota1
qplot(x = x[seq(1:45)],y=aliquota1)

# 2. uc - projetado % sal�rio

# c�lculo do k
k1 <- Br / sum(sal�rios[1:(r-y)])
k1

# c�lculo do bx
bx2 <- k1 * sal�rios[1:(r-y)]
bx2
qplot(x = x[seq(1:45)],y = bx2, xlab = "idade")
length(bx2)

# c�lculo do Bx
Bx2 <- function(bx, n){
  B <- rep(0, n+1)
  
  for(a in 2:(n+1)){
    B[a] <- B[a-1] + bx[a-1]
  }
  return(B)
}

Bacum2 <- Bx2(bx2, r - y)
Bacum2
qplot(x=x, y=Bacum2)

# C�lculo do CN
cn2 <- bx2 * pvar[1:(r-y)]
cn2
plot(cn2)

# C�lculo do ALx
ALx2 <- Bacum2 * pvar
ALx2
plot(ALx2)

# C�lculo da Al�quota
aliquota2 <- (cn2 / sal�rios[1:(r-y)]) * 100
aliquota2
plot(aliquota2)

# UC - Projetado - M�dia s/ 'n' sal�rios

# c�lculo do k 
k2 <- (Br * med_n)/((r - y)*(sum(vetor_sal�rio(sy, cs, r - y))-sum(vetor_sal�rio(sy, cs, r - y - med_n))))
k2
 
# C�lculo do bx
# Se x < y + n, bx = k * sx
# quando x >= y + n, bx = n/k * [(x - y)*(sx - sx-n)+(Sx+1 - Sx+1-n)]

bx3 <- function(k, n, sy, idade, t, cs){
  # n = anos para a m�dia
  # idade = idade de in�cio
  # t = tempo de contribui��o
  # sy = salario inicial
  # cs = crescimento salarial
  
  g <- 0
  cont <- 1

  while(cont <= n){
    g[cont] <- k * sal�rio(sy, cs, cont - 1)
    cont <- cont + 1
    
  }
  
  for(l in cont:t){
    g[l] <- (k/n)*(((l - 1) * (sal�rio(sy, cs, l - 1) - sal�rio(sy, cs, l - n - 1))) + (sum(vetor_sal�rio(sy, cs, l - 1)) - sum(vetor_sal�rio(sy, cs, l - n - 1))))
  
    }
  return(g) 
}


bx3 <- bx3(k = k2, n = med_n, sy = sy, idade = y, t = r - y, cs = cs)
bx3
plot(bx3)

# C�lculo do Bx
Bacum3 <- Bx2(bx3, r - y)
Bacum3

# C�lculo do CN
cn3 <- bx3 * pvar[1:(r-y)]
cn3
plot(cn3)

# C�lculo do ALx
ALx3 <- Bacum3 * pvar
ALx3
plot(ALx3)

# Al�quota 
al�quota3 <- (cn3/sal�rios)*100
al�quota3
plot(al�quota3)

# Aloca��o de Custo - IEN

# Calcular o CNy
cn4 <- VPBF[1]/axn(tabua, x = y, n = r - y, i = i)
cn4

# Calcular o Passivo Atuarial 
PassivoAC <- function(VPBF, y, r){
    passivo <- 0
    cont <- 1
    for(k in 2:(r-y + 1)){
      passivo[k] <- VPBF[k]*(axn(tabua, x = y, n = cont, i = i)/axn(tabua, x = y, n = r - y, i = i))
      cont <- cont + 1}  
     
    return(passivo) 
}
ALx4 <- PassivoAC(VPBF, y, r) 
ALx4

# Al�quota
al�quota4 <- (cn4/sal�rios)*100
al�quota4
plot(al�quota4)

