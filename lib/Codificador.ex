defmodule Codificador do

  def codificar_data_vencimento(data_str) do
    # Converte em um objeto do tipo Date
    data_lista = data_str |> String.split("/") |> Enum.map(&String.to_integer/1)
    data_entrada = Date.new(Enum.at(data_lista,2), Enum.at(data_lista,1), Enum.at(data_lista,0)) |>
    elem(1)
    # Data base
    data_base = ~D[1997-10-07]
    # Calcula o fator de vencimento
    fator_de_validade = Date.diff(data_entrada, data_base)
    if (fator_de_validade > 9999) do
      # Reinicia a contagem do fator, caso ultrapasse o valor 9999
      1000 + rem(fator_de_validade, 1000) |> Integer.to_string # Reinicia a contagem do fator
    else
      fator_de_validade |> Integer.to_string
    end
  end

  # A entrada deve ser do tipo String
  def codificar_valor(valor_string) do
    # Caso o número fornecido não tenha casas decimais, adicionamos ".00" ao fim da string
    if !String.contains?(valor_string, [".", ","]) do
      String.pad_trailing(valor_string, String.length(valor_string) + 3, ".00")
    end
    # Converte valor em string e remove qualquer possível lixo ("R$", "$", ".", "," etc)
    valor =  valor_string |> String.replace(["R$", "$", ".", ",", " "], "")
    String.pad_leading(valor, 10,"0")
  end

  # Função auxiliar para o código do DV. Calcula o somatorio dos dígitos do codigo com seus devidos pesos
  def soma_dv(codigo, peso_atual) when byte_size(codigo) == 1 do # Quando há apenas um digito restante do codigo (parada)
    String.to_integer(codigo) * peso_atual
  end
  # Quando o peso está em [2, 8]
  def soma_dv(codigo, peso_atual) when peso_atual < 9 do
    # Extrai último termo da string do codigo e converte para inteiro
    digito_atual = codigo |> String.last() |> String.to_integer()
    # Retira ultima letra da string "codigo" para a chamada recursiva da função
    codigo_sem_ultimo = String.slice(codigo, 0, String.length(codigo) - 1)
    (digito_atual * peso_atual) + soma_dv(codigo_sem_ultimo, peso_atual + 1)
  end
  # Quando o peso está em 9 ,resetamos o valor para 2
  def soma_dv(codigo, peso_atual) do
    digito_atual = codigo |> String.last() |> String.to_integer()
    codigo_sem_ultimo = String.slice(codigo, 0, String.length(codigo) - 1)
    (digito_atual * peso_atual) + soma_dv(codigo_sem_ultimo, 2)
  end
  # Calcula o DV do código, retorna o código de barras com DV incluso
  def calcular_dv_codigo_de_barras(codigo_sem_dv) do
    somatorio_dos_termos = soma_dv(codigo_sem_dv, 2)
    fator = 11 - rem(somatorio_dos_termos, 11)
    if fator in [0, 10, 11] do
      (codigo_sem_dv |> String.slice(0, 3)) <> "1" <> (codigo_sem_dv |> String.slice(4, 39))
    end
    (codigo_sem_dv |> String.slice(0, 4)) <> Integer.to_string(fator) <> (codigo_sem_dv |> String.slice(4, 39))
  end

    # === Linha Digitável === #
  # Transforma uma String em uma lista
  def stringToList(string) do
    for<<x::binary-1 <- string>>, do: x
  end

  # Multiplica cada elemento da lista com base no valor do parametro numero
  def alternar([h|l],numero) when numero == 1 do
    [h|alternar(l,2)]
  end

  def alternar([h|l],numero) when numero == 2 do
    # Quando h é maior que 4 o resultado da multiplicação por 2 é maior ou igual a 10, necessitando de um cálculo diferente
    if h > 4 do
      resultado = h*2
      |>Integer.to_string()
      |>stringToList()
      |>Enum.map(fn x -> String.to_integer(x) end)
      |>Enum.reduce(0,fn x,y -> x+y end)
      [resultado|alternar(l,1)]
    else
      [h*2|alternar(l,1)]
    end
  end
  # Critério de parada da função alternar
  def alternar([], _) do
    []
  end

  # Recebe uma String e um inteiro que sinaliza em que campo aquela String se refere
  # Retorna o dv do campo no formato interiro
  def digitoVerificadorLinha(linha,campo) when campo == 1 do
    resultado = linha
    |>stringToList()
    |>Enum.map(fn x -> String.to_integer(x) end)
    |>alternar(2)
    |>Enum.reduce(0,fn x,y -> x+y end)
    |>rem(10)
    10 - resultado
  end

  # Cálculo dos campo 2 e 3 funcionam da mesma forma, então nesse caso a especificação do campo é irrelevante
  def digitoVerificadorLinha(linha,_) do
    resultado = linha
    |>stringToList()
    |>Enum.map(fn x -> String.to_integer(x) end)
    |>alternar(1)
    |>Enum.reduce(0,fn x,y -> x+y end)
    |>rem(10)
    10-resultado
  end

  # Constrói a linha digitável
  def codificar_linha_digitavel(codigo_de_barras) do  # será a ultima funcao chamada, pois precisa do codigo inteiro
  # Campo 1
  str1 = (codigo_de_barras |> String.slice(0, 4)) <> (codigo_de_barras |> String.at(19)) <> "." <> (codigo_de_barras |> String.slice(20,4))
  campo1 = str1 <> (str1 |> String.replace(".","") |> digitoVerificadorLinha(1) |> Integer.to_string)
  # Campo 2
  str2 = (codigo_de_barras |> String.slice(24, 5)) <> "." <> (codigo_de_barras |> String.slice(29, 5))
  campo2 = str2 <> (str2 |> String.replace(".","") |> digitoVerificadorLinha(2) |> Integer.to_string)
  # Campo 3
  str3 = (codigo_de_barras |> String.slice(34, 5)) <> "." <> (codigo_de_barras |> String.slice(39, 5))
  campo3 = str3  <> (str3 |> String.replace(".","") |> digitoVerificadorLinha(3) |> Integer.to_string)
  # Campo 4
  campo4 = codigo_de_barras |> String.at(4)
  # Campo 5
  campo5 = (codigo_de_barras |> String.slice(5, 4)) <> (codigo_de_barras |> String.slice(9, 10))
  # Montagem da linha
  campo1 <> " " <> campo2 <> " " <> campo3 <> " " <> campo4 <> " " <> campo5
  end

  defp saida_codificador(lista) do
    # Abre uma stream que receberá as strings
    saida = "Código de Barras: " <> Enum.at(lista, 0) <> "\n"
    <> " Linha Digitável: " <> Enum.at(lista, 1)
    saida
  end

  # Caso a entrada seja dada como vetor de dados
  def codificar(dados) when is_list(dados) do
    # Captura as partes codificadas do código
    codigo_do_banco = dados |> Enum.at(0)
    moeda = dados |> Enum.at(1)
    fator_de_validade = dados |> Enum.at(2) |> codificar_data_vencimento
    valor = dados |> Enum.at(3) |> codificar_valor()
    nosso_numero = dados |> Enum.slice(4, 8) |> List.to_string()
    codigo_de_barras = codigo_do_banco <> moeda <> fator_de_validade <> valor <> nosso_numero |>
    calcular_dv_codigo_de_barras()
    linha_digitavel = codigo_de_barras |> codificar_linha_digitavel()
    #Gera um arquivo .PNG do código de barras
    codigo_de_barras |> gerar_codigo_de_barras()
    # Chama a função IO
    [codigo_de_barras, linha_digitavel] |> saida_codificador() |> IO.puts()
  end

  # Caso seja fornecido um arquivo como entrada (test/codificador_test_file.txt é o default)
  def codificar(arquivo \\ "codificador_file.txt") do
    arquivo |> File.read |> elem(1) |> String.split("\n") |> codificar
  end

 #Caso o arquivo barcode.png não exista ele será criado da pasta do projeto
 #Caso ele já exista ele será substituido pelo novo código de barras
  def gerar_codigo_de_barras (codigo) do
    Barlix.ITF.encode!(codigo) |> Barlix.PNG.print(file: "barcode.png")
  end

end
