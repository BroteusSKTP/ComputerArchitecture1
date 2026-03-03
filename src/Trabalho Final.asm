.globl main
.data #inicialização de data segment
	
	input: .asciz  "cat_noisy.gray" 			#string com nome do ficheiro gray
	original: .space 239600 				#espaço onde colocaremos os bytes (pixeis) do ficheiro gray original (cat_noisy.gray)
	modificado: .space 239600				#espaço onde colocaremos os bytes (pixeis) alterados pelos filtros
	arraymediana:	.space 9				#espaço alocado para os bytes da matriz 3x3 (ao redor do byte inclusive a ser trabalhado) para descobrir mediana
	ficheiromedia: .asciz "cat_noisy_media.gray" 		#nome do ficheiro novo tendo usado o método filtro de média
	ficheiromediana: .asciz "cat_noisy_mediana.gray"	#nome do ficheiro novo tendo usado o médtodo filtro de mediana
	sucesso: .asciz "Filtro aplicado com sucesso!\n\n"	#mensagem que indica que o filtro foi aplicado com sucesso
	colunas: .half 599					#variável glocal com o número de colunas existentes na matriz
	linhas: .half 400					#variável global com o número de linhas existentes na matriz

.text #inicialização do codigo/instrução																				

#########################################################################################################################################################################
# Funcao: matriz
# Descricao: Esta funcao calcula o número do byte que pretendemos tratar numa matriz e determina se e que filtro usar para o seu tratamento.
# Argumentos:
# a0 - contador que identifica que filtro pretendemos usar
# Retorna:
# a0 - retorna o endereço da string que contém a mensagem "Filtro aplicado com sucesso!"
#########################################################################################################################################################################
	
	#inicio da função e inicialização de registos a serem usados
matriz:
	
	addi sp, sp, -32	#incrementação da stack para armazenar o conteúdo dos registro s0-6 mais o endereço contido ra (haverá chamada de outras funções)
	sw s0, 28(sp)		#temos que manter a integridade do valor contido anteriormente nos registros S se forem modificados numa função
	sw s1, 24(sp)		
	sw s2, 20(sp)
	sw s3, 16(sp)
	sw s4, 12(sp)
	sw s5, 8(sp)
	sw s6, 4(sp)
	sw ra, 0(sp)		
	
	la s0, colunas		#load do endereço onde se encontra a variável global com o número de colunas da matriz
	lhu s0, 0(s0)		#load do valor contido na variável global (número de colunas) para s0/ unsigned para garantir que são carregados valores de 0-255 (invés de -128 a 127)
	addi s0, s0, -1		#decrementamos menos 1 ao número de colunas existentes na matriz para o calculo do endereço do byte a ser modificado (consideramos que vai de 0-598 colunas)
	
	la s1, linhas		#load do endereço onde se encontra a variável global com o número de linhas da matriz
	lhu s1, 0(s1)		#load do valor contido na variável global (número de linhas) para s1/ unsigned para garantir que são carregados valores de 0-255 (invés de -128 a 127)
	addi s1, s1, -1		#decrementamos 1 ao número de linhas existentes na matriz para o calculo do endereço do byte a ser modificado (consideramos que vai de 0-399 linhas)
	
	li s2, 0		#registro que contém o número da linha em que se encontra o byte a ser trabalhado (0 - 1ª linha| 1 - 2ª linha| etc... ou seja, 0-399)
	li s3, 0		#registro que contém o número correspondente à posição do byte (que vai ser trabalhado) numa dada linha (0-598)
	li s4, 255		#registro que contém a intensidade = branco para store
	la s5, original		#registro que contém o endereço do espaço reservado para os bytes em memoria (buffer)
	mv s6, a0		#registro que contém o contador responsavel por se usar o filtro de media/mediana
	
	
	# 0 | 1 | 2 |.............................................................................................................................| 598 #
#########################################################################################################################################################
#   0	# 0 | 1 | 2 |.............................................................................................................................| 598 #
#   1	# 599 | 600 |............................................................................................................................| 1197 #
#   2	# 1198 |.................................................................................................................................| 1796 #
#   .	#   .																	   -	#
#   .	#   .																	   -	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#   .	#   .																	   .	#
#  399	# 239001 |.............................................................................................................................| 239599 #
#########################################################################################################################################################
	
	
	#Calculo do byte a ser trabalhado, chamada de função de acordo com as condições estabelecidas (arestas a branco/ média/ mediana)
loopcalculo:
	
	addi a0, s0, 1  		#acerto do número de colunas existentes na realidade (599) e colocada como argumento para função multi
	mv a1, s2			#passar para argumento para a chamada da função multi, o número da linha em que se encontra o byte a ser trabalhado
	jal multi			#calculo do primeiro byte de uma dada linha (linha 0 , byte = 0 | linha 1 , byte = 599 | linha 2 , byte = 1098......etc)
					#(mul a0, a0, a1 para execução do programa mais rápido/ jal multi para usar a função multiplicação)
					
	add a0, a0, s3			#soma da posição do byte a ser trabalhado com o primeiro byte determinado na operação anterior (Exemplo: terceiro byte da linha 1 = 599 + 2)

	la a1, modificado		#load endereço do espaço reservado aos bytes alterados pelos filtros
	add a1, a1, a0			#calculo do endereço do byte a ser guardado após ser modificado pelo filtro (modificado)
	add a0, a0, s5			#calculo do endereço do byte a ser trabalhado
	
	#Verifica se o byte trabalhado pertence à aresta da figura ou a manda para ser aplicada o filtro media/mediana
	beqz s2, branco			#se o número da linha do byte a ser trabalhado for zero (primeira linha), salta para a parte em que se coloca a branco
	beq s2, s1, branco		#se o número da linha do byte a ser trabalhado for igual a 399, salta para a parte em que se coloca a branco
	beqz s3, branco			#se o número da coluna do byte a ser trabalhado for igual a zero, salta para a parte em que se coloca a branco
	beq s3, s0, branco		#se o número da coluna do byte a ser trabalhado for igual a 598, salta para a parte em que se coloca a branco
	
	bnez s6, funcaomediana		#se o contador for maior ou igual que zero vai para função mediana			
	jal media			#chama a função media com a0 = ao endereço do byte que estamos a trabalhar
	j nextbyte			#quando retorna vai para o nextbyte
	
funcaomediana:

	jal mediana			#se o contador for zero então irá enviar como a0, o endereço do byte a ser trabalhado pafra a função mediana
	j nextbyte			#quando retorna vai para o nextbyte (faz verificação e reset)
	
branco:
	
	sb s4, 0(a1)			#neste caso o byte a ser trabalhado passa a ser 255 pois pertence à aresta e deve de estar a branco
	
	#acerto para passar ao proximo byte a ser trabalhado
nextbyte:

	addi s3, s3, 1			#adiciona mais um à posição do byte a ser trabalhado numa determinada linha
	bgt s3, s0, last		#se a posição do byte for maior que o número de colunas existentes na matriz então temos que fazer uma ultima verificação (last)
	j loopcalculo			#salto incondicional para o inicio do loop do calculo
	
last:	
	addi s2, s2, 1			#adiciona mais um ao registo que contém o número da linha do byte que estamos a trabalhar
	bgt s2, s1, matrizexit		#se a linha do byte a ser trabalhado for maior que o número de linhas existente na matriz então todos os bytes já foram tratados e salta para o fim da função
	li s3, 0			#se não então fazemos reset à posição do byte numa dada linha para zero e continuamos na linha nova
	j loopcalculo			#salto incondicional para o inicio do loop do calculo

	#fim da função (percorreu toda a matriz)
matrizexit:

	la a0, sucesso			#retorna valor zero em a0 para que indique que o filtro media/mediana foi aplicado com sucesso em toda a matriz
	lw s0, 28(sp)			#recupera os dados copiados para a stack (no inicio da funcao) de volta aos seus registros iniciais			
	lw s1, 24(sp)
	lw s2, 20(sp)
	lw s3, 16(sp)
	lw s4, 12(sp)
	lw s5, 8(sp)
	lw s6, 4(sp)
	lw ra, 0(sp)			#recupera o endereço de retorno para o ra (return address)
	addi sp, sp, 32			#decrementação do stack pointer para libertar o espaço reservado no inicio da função
	ret				#jal zero, 0(ra)
	
#########################################################################################################################################################################
# Funcao: Média
# Descricao: Função que faz a média dos bytes da matriz 3x3 (ao redor do byte a ser trabalhado)
# Argumentos:
# a0 - Endereço do byte a ser trabalhado
# a1 - Endereço onde fazemos store ao byte modificado
# Retorna:
# a0 - Retorna void (lixo)
#########################################################################################################################################################################	
	
	#inicio da função e inicialização de registos a serem usados
media:
	addi sp, sp, -8			#criamos espaço na stack para armazenar o endereço (da instrução a seguir ao jal media na matriz) e o contéudo do registo s0
	sw s0, 4(sp)
	sw ra, 0(sp)
	
	mv s0, a0			#registo que vai conter o endereço do byte a ser trabalhado																
	li t0, 0			#registo que contém o somatorio dos 9 bytes da matriz 3x3	                                      	
	li t1, -1			#counter responśavel por correr do byte à esquerda ao byte da direita                                 
	li t2, -1			#counter reponsável pela linha do byte (acima ou abaixo)					     
	la t3, colunas			#load do endereço para t3, do número de colunas existentes na matriz imagem		      
	lhu t3, 0(t3)			#load do número de colunas existentes na matriz para calculo de endereços (no mesmo registo)	      
	li t5, 1			#valor para uso de branch (sair do loopmedia)
	mv t6, a1			#movemos o endereço para onde faremos store ao byte modificado para t6 para usar a1 na função multi						      
	        															      
	#loop responśavel por fazer load e soma dos valores dos 9 bytes pertencentes à matriz 3x3 em que determinamos a mediana 	      
loopmedia:
	
	mv a0, t2		#movemos para a0 o primeiro elemento da multiplicação
	mv a1, t3		#movemos para a1 o segundo elemento da multiplicação
	jal multi		#call da função multi para multiplicarmos a linha pelo número de colunas existentes na matriz
				#(mul a0, a0, a1 para execução do programa mais rápido/ jal multi para usar a função multiplicação)
	
	add t4, a0, t1		#somamos ao produto anterior a posição do byte (esquerda - direita)
	add t4, t4, s0		#somamos o resultado anterior ao endereço do byte que estamos a trabalhar
	
	lbu t4, 0(t4)		#load do byte que se encontra no endereço calculado em cima para t4
	add t0, t0, t4		#soma do valor contido em t0 com o valor que fizemos load para t4

	addi t1, t1, 1			#somamos um ao counter responsável por correr os bytes (esqerda-direita)
	ble t1, t5, loopmedia		#se o counter for menor ou igual a -1, então voltamos para o loopmedia
	
	addi t2, t2, 1			#se o counter anterior for maior que 1, então somamos 1 ao counter responsável pela linha do byte
	li t1, -1			#e reiniciamos o counter responsavel pela posição do byte (esquerda-direita)
	ble t2, t5, loopmedia		#se o counter responsavel pela linha do byte for menor ou igual que 1 então voltamos para o loop
	
	#Exemplo: queremos calcular o endereço do primeiro byte da primeira fila (599 * (-1) = -599|  -599 + (-1) = -600|  
	#Endereço do byte a que queremos aplicar o filtro + (-600) = Endereço do byte que queremos fazer load para operação média/mediana
	  
	#chamada da função div e store byte depois de aplicada o filtro no array modificado

	mv a0, t0		#movemos a soma dos valores contidos dos 9 bytes da matriz 3x3 para a0 (chamar função divi)
	li a1, 9		#guarda no a1, o divisor para a média (que é 9)
	jal divi		#chama a função divisão (instrução div a0, a0, a1 para execução mais rapida do programa, jal divi para chamada da função divisão)
		
	sb a0, 0(t6)		#guarda o byte modificado no endereço destino determinado na matriz (array modificado)
	lw s0, 4(sp)
	lw ra, 0(sp)		#faz load do return address para fazer o ret para a função matriz
	addi sp, sp, 8		#esvazia o espaço reservado no stack pointer
	
	ret			# jal zero, 0(ra) 

#########################################################################################################################################################################
# Funcao: Mediana
# Descricao: Função que faz a mediana dos bytes da matriz 3x3 (ao redor do byte a ser trabalhado)
# Argumentos:
# a0 - Endereço do byte a ser trabalhado
# a1 - Endereço onde fazemos store ao byte modificado
# Retorna:
# a0 - Retorna void (lixo)
#########################################################################################################################################################################
		
	#inicio da função e inicialização de registos a serem usados
mediana:
	
	addi sp, sp, -8			#criamos espaço na stack para armazenar o endereço (da instrução a seguir ao jal mediana na matriz) e o conteúdo do registo s0
	sw s0, 4(sp)
	sw ra, 0(sp)
	
	mv s0, a0			#registo que vai conter o endereço do byte a ser trabalhado	
	la t0, arraymediana		#endereço do array temporário que vai armazenar os 9 bytes pertencentes à matriz 3x3 a ser trabalhada
	li t1, -1			#counter responśavel por correr do byte à esquerda ao byte da direita
	li t2, -1			#counter reponsável pela linha do byte (acima ou abaixo)
	la t3, colunas			#load do endereço para t3, do número de colunas existentes na matriz imagem
	lhu t3, 0(t3)			#load do número de colunas existentes na matriz para calculo de endereços
	li t5, 1			#valor para uso de branch
	mv t6, a1			#movemos o endereço para onde faremos store ao byte modificado para t6 para usar a1 na função multi	
	
	#loop responśavel por fazer load e store num novo array temporario, dos 9 bytes que pertencem à matriz 3x3 em causa 
loopstorearray:
	
	mv a0, t2		#movemos para a0 o primeiro elemento da multiplicação
	mv a1, t3		#movemos para a1 o segundo elemento da multiplicação
	jal multi		#call da função multi para multiplicarmos a linha pelo número de colunas existentes na matriz 
				#(mul a0, a0, a1 para execução do programa mais rápido/ jal multi para usar a função multiplicação)
	
	add t4, a0, t1		#somamos ao produto anterior a posição do byte (esquerda - direita)
	add t4, t4, s0		#somamos o resultado anterior ao endereço do byte que estamos a trabalhar
	
	lbu t4, 0(t4)		#load byte do endereço calculado
	sb t4, 0(t0)
	addi t0, t0, 1

	addi t1, t1, 1			#somamos um ao counter responsável por correr os bytes (esqerda-direita)
	ble t1, t5, loopstorearray	#se o counter for menor ou igual a 1, então volta para o loop
	
	addi t2, t2, 1			#se o counter anterior for maior que 1, então somamos 1 ao counter responsável pela linha do byte
	li t1, -1			#e reiniciamos o counter responsável pela posição do byte (esquerda-direita)
	ble t2, t5, loopstorearray	#se o counter responsável pela linha do byte for menor ou igual que 1 então voltamos para o loop
	
	
	#inicio da segunda fase da função mediana, onde se reordena os 5 bytes mais à direita do array temporário (do mais pequeno para o maior)
	li t5, 5		#a partir de aqui o registro t5 irá conter o counter que indica o número de vezes que iremos percorrer o array

loopexterno:

	la t0, arraymediana	#reset para o endereço do primeiro byte do arraymediana
	li t4, 8		#a partir daqui o registro t4 irá conter o counter com número de comparações que queremos fazer no array (num array de 9 elementos fazemos 8 verificações de maior ou menor até ao fim deste)

loopinterno:

	lbu t1, 0(t0)		#load do primeiro byte do array a ser comparado
	lbu t2, 1(t0)		#load do segundo byte do array a ser comparado
	
	ble t1, t2, endmedi	#se o primeiro byte for menor ou igual que o segundo byte então salta para endmedi
	mv t3, t2		#se o primeiro byte for maior que o segundo então trocam se bytes nos registos. Usamos o t3 agora como intermédio visto que já não precisamos do número de colunas
	mv t2, t1
	mv t1, t3
	
	sb t1, 0(t0)		#aqui colocamos os valores contidos nos registos nas suas devidas posições no arraymediana
	sb t2, 1(t0)

	#faz se as verificações de fim dos loops e store do byte do meio do array temporário (a mediana da matriz 3x3 em questão) para o array modificado
endmedi:	

	addi t0, t0, 1			#somas 1 ao endereço do array
	
	addi t4, t4, -1			#subtrais 1 ao counter com número de comparações
	bgtz t4, loopinterno		#se este counter for maior que zero, volta para o loopinterno
	
	addi t5, t5, -1			#senão já percorremos o array todo, decrementamos 1 ao counter responsável pelo número de vezes que queremos percorrer o array
	bgtz t5, loopexterno		#se este counter for maior que zero, saltamos para o loopexterno
	
	lbu t0, -4(t0)			#load byte do quinto elemento para o t0
	sb t0, 0(t6)			#store desse byte no array dos bytes modificados
	
	lw s0, 4(sp)
	lw ra, 0(sp)			#load do endereço guardado no inicio da função para ra
	addi sp, sp, 8  		#libertamos o espaço criado na stack para guardar o endereço anterior
	
	ret				#jal zero, ra(0)
	
#########################################################################################################################################################################
# Funcao: Multiplicação
# Descricao: Esta funcao faz a multiplicação entre dois argumentos
# Argumentos:
# a0 - primeiro elemento da multiplicação
# a1 - segundo elemento da multiplicação
# Retorna:
# a0 - produto final
#########################################################################################################################################################################
		
	#inicio da função + inicialização de registos a serem usados							
multi:
	addi sp, sp, -8		#cria espaço na stack e guarda os valores contidos nos registos t0 e t1 pois vão ser usados
	sw t0, 4(sp)
	sw t1, 0(sp)
	
	mv t0, a0		#move se o primeiro elemento a multiplicar para t0 e colcamos a0 a 0
	li t1, 0		#inicia se o registo t1 a zero, que vai servir de counter para verificar sinal final do produto
	li a0, 0		#coloca a0 a zero e vai servir para conter o produto final
					
	#verificação do sinal de cada elemento
	bgez t0, signalmulti	#salta para a proxima verificação se o t0 tem um valor positivo
	sub t0, zero, t0	#se for menor que zero, então muda se o sinal
	addi t1, t1, 1		#adiciona 1 ao registo t1

signalmulti:

	bgez a1, loopmulti	#salta para a proxima verificação se a1 for um valor positivo
	sub a1, zero, a1	#se for menor que zero, então muda se o sinal
	addi t1, t1, 1		#adiciona 1 ao registo t1
	
	#multiplicação (soma n vezes) de dois números positivos														
loopmulti:						
	
	beqz a1, signalfixmulti		#quando a1 for igual a zero, salta se para verificação final																									
	add a0, a0, t0			#soma se a0 a a0 o número de vezes que se encontra em a1				
	addi a1, a1, -1
	j loopmulti			#salto incondicional para repetir loop ou fazer verificação e sair
	
	#verificação do sinal correcto do resultado final
signalfixmulti:

	andi t1, t1, 1		#coloca em t1 1 se o número do counter for impar e 0 se for par
	beqz t1, endmulti	#se t1 for igual a zero então o produto final é positivo e salta se para o fim da função
	sub a0, zero, a0	#se t1 for 1 (diferente de zero) então altera se o sinal do produto final (negativo)

endmulti:
	
	lw t0, 4(sp)		#recupera os valores guardados na stack para os devidos registos e liberta o espaço criado
	lw t1, 0(sp)
	addi sp, sp, 8	
	ret			#jal zero, ra(0)

#########################################################################################################################################################################
# Funcao: Divisão
# Descricao: Esta funcao faz a operação divisão
# Argumentos:
# a0 - Dividendo
# a1 - Divisor
# Retorna:
# a0 - Quociente
#########################################################################################################################################################################
		
	#inicio da função + inicialização de registos a serem usados
divi:

	addi sp, sp, -8		#cria espaço na stack e guarda os valores contidos nos registos t0 e t1 pois vão ser usados
	sw t0, 4(sp)
	sw t1, 0(sp)
	
	mv t0, a0		#move se o dividendo para t0
	li t1, 0		#inicia se o registo t1 a zero, que vai servir de counter para verificar sinal final da divisão
	li a0, 0		#coloca a0 a zero e vai servir para conter a divisão final
	
	#verificação do sinal de cada elemento
	bgez t0, signaldiv	#salta para a proxima verificação se o t0 tem um valor positivo
	sub t0, zero, t0	#se for menor que zero, então muda se o sinal
	addi t1, t1, 1		#adiciona 1 ao registo t1

signaldiv:

	bgez a1, loopdivi	#salta para a proxima verificação se a1 for um valor positivo
	sub a1, zero, a1	#se for menor que zero, então muda se o sinal
	addi t1, t1, 1		#adiciona 1 ao registo t1
	
	#divisão entre dois números positivos
loopdivi:

	bgt a1, t0, signalfixdivi	#quando a1 (divisor) for maior que t0, salta se para verificação final
	sub t0, t0, a1			#a0 armazena o número de vezes que subtraimos ao dividendo o divisor até que não consigamos mais sem que fique negativo
	addi a0, a0, 1
	j loopdivi		#salto incondicional para repetir loop ou fazer verificação e sair

signalfixdivi:

	andi t1, t1, 1		#coloca em t1 1 se o número do counter for impar e 0 se for par
	beqz t1, enddivi	#se t1 for igual a zero então a divisão final é positiva e salta se para o fim da função
	sub a0, zero, a0	#se t1 for 1 (diferente de zero) então altera-se o sinal do quociente (negativo)

enddivi:

	lw t0, 4(sp)		#recupera os valores guardados na stack para os devidos registos e liberta o espaço criado
	lw t1, 0(sp)
	addi sp, sp, 8	
	ret			#jal zero, ra(0)
													
#########################################################################################################################################################################
# Funcao: Main
# Descricao: Esta função inicia o programa, faz a chamada de funções e system calls (inclusive terminar o programa)																																																																																																																																																																																																																																																																																																																																						
#########################################################################################################################################################################
	
	#inicio do programa
main:
	
	# abrir ficheiro cat_noisy.gray																	
	la a0, input 	#coloca em a0, o endereço da label input (nome do ficheiro)											
	li a1, 0 	#coloca a1 o número da flag (0 para read-only)													
	li a7, 1024 	#coloca a7 o número 1024 (open file)														
	ecall		#retorna a0 o file descriptor de cat_noisy.gray	
																					
	mv s11, a0	#guardar o file descriptor do cat_noisy.gray no s11 pois quando lermos o ficheiro para memoria 							
			#(no passo seguinte) iremos ter o tamanho do que foi lido retornado no valor a0 e iremos precisar para quando fecharmos o ficheiro
	
	
	# ler o ficheiro e colocar os bytes em memória
	la a1, original	#coloca endereço do espaço reservado no a1
	li a2, 239600	#coloca o número bytes necessários para guardar os bytes
	li a7, 63	#coloca em a7 o 63 (read file)
	ecall		#retorna no a0 o tamanho dos bytes lidos	
	
	
	# fechar ficheiro cat_noisy.gray
	mv a0, s11	#coloca o file descriptor do cat_noisy.gray no a0
	li a7, 57 	#coloca 57 em a1 para fechar o ficheiro cat_noisy.gray (a0 continua com o file descriptor)
	ecall
	
#########################################################################################################################################################################

	# Modificar bytes com filtro média
	li a0, 0	#contador que permite identificar se estamos a usar o filtro de media ou mediana (media = 0 e mediana != 0)
	jal matriz
	li a7, 4
	ecall		#printf com mensagem de sucesso
	
#########################################################################################################################################################################	
	
	# criar ficheiro cat_noisy_media.gray
	la a0, ficheiromedia	#coloca o endereço que contém o nome do novo ficheiro
	li a1, 1		#coloca 1 no a1 para write-only (se o ficheiro não existe cria um novo)
	li a7, 1024 		#coloca 1024 no a7 (open file)
	ecall			#retorna a0 o file descriptor de cat_noisy_media.gray
	
	mv s10, a0	#coloca o file descriptor de cat_noisy_media.gray no s10 pois quando lermos o ficheiro para memoria
			#(no passo seguinte) iremos ter o de caracteres escritos retornados no a0 e iremos precisar para quando fecharmos o ficheiro
	
	
	# escrever no cat_noisy_media.gray
	la a1, modificado 	#coloca o endereço space no a1
	li a2, 239600		#coloca o número de bytes do cat_noisy_media.gray
	li a7, 64		#coloca 64 no a7 (write file)
	ecall 			#retorna no a0, número de char escritos
	
	
	# fechar ficheiro cat_noisy_media.gray
	mv a0, s10	#coloca o file descriptor do cat_noisy.gray no a0
	li a7, 57 	#coloca 57 em a1 para fechar o ficheiro cat_noisy.gray
	ecall	
		
########################################################################################################################################################################

	# Modificar bytes com filtro média
	li a0, 1	#contador que permite identificar se estamos a usar o filtro de media ou mediana (media = 0 e mediana != 0)
	jal matriz
	li a7, 4
	ecall		#printf com mensagem de sucesso
	
#########################################################################################################################################################################
	
	# criar ficheiro cat_noisy_mediana.gray
	la a0, ficheiromediana		#coloca o endereço que contém o nome do novo ficheiro
	li a1, 1		#coloca 1 no a1 para write-only (se o ficheiro não existe cria um novo)
	li a7, 1024 		#coloca 1024 no a7 (open file)
	ecall			#retorna a0 o file descriptor de cat_noisy_mediana.gray
		
	mv s11, a0	#coloca o file descriptor de cat_noisy_mediana.gray no s10 pois quando lermos o ficheiro para memoria
			#(no passo seguinte) iremos ter o de caracteres escritos retornados no a0 e iremos precisar para quando fecharmos o ficheiro
			
	
	# escrever no ficheiro cat_noisy_mediana.gray
	la a1, modificado	#coloca o endereço space no a1
	li a2, 239600		#coloca o número de bytes do cat_noisy_mediana.gray
	li a7, 64		#coloca 64 no a7 (write file)
	ecall
	
	
	# fechar ficheiro cat_noisy_mediana.gray
	mv a0, s11	#coloca o file descriptor do cat_noisy_mediana.gray no a0
	li a7, 57 	#coloca 57 em a1 para fechar o ficheiro cat_noisy.gray (a0 continua com o file descriptor)
	ecall
	
#######################################################################################################################################################################	
	
	# encerrar programa
	li a7, 10
	ecall
	
#######################################################################################################################################################################
