function math.eval(str)
  -- Calculate string math expression (without function)
  str = str:gsub(" ", "")
  if str == "" or type(str) ~= "string" then return false end

  function pop(t)
    -- Delete the last element of a table and return it
    local d = t[#t];table.remove(t, #t);return d
  end

  function styard(str)
    -- Convert infix to post fix with shunting yard algorithm

    function fotab (str)
      -- Formula to table
      -- LeftBracket(0 or more) Signe+-(0 or 1) Number(int or float with comma) RightBracket(0 or more) Operator(0 or 1)
      -- Exemple "-4*10.54+((10+8)*3.141592)" -> {"-","4","*","10.54","+","(","(","10",...}
      local t = {}
      for lb, s, n, rb, o in str:gmatch("(%(*)([-+^]?)(%d+%.?%d*)(%)*)([-*/+^]?)") do
        local raw_t = {lb, s, n, rb, o}
        for i=1,#raw_t do
          if raw_t[i] ~= "" then
            table.insert(t, raw_t[i])
          end
        end
      end
      for i=1,#t do
        if #t[i] > 1 and (t[i]:match("%(+") or t[i]:match("%)+")) then
          local h, c = #t[i]-1, t[i]:sub(1, 1)
          t[i] = c
          for j=1,h do
            table.insert(t, i, c)
          end
        end
      end
      return t
    end

    local tokens, queue, stack, operators = fotab(str), {}, {}, {}
    operators["^"] = {4, "Right"}
    operators["/"] = {3, "Left"}
    operators["*"] = {3, "Left"}
    operators["+"] = {2, "Left"}
    operators["-"] = {2, "Left"}

    for i=1,#tokens do
      if tokens[i]:find('%d') then
        table.insert(queue, tokens[i])
      elseif tokens[i]:find('[+/*^-]') then
        local o1, o2 = tokens[i], stack[#stack]
        while (o2 ~= nil and o2:find('[+/*^-]') and ((operators[o1][2] == "Left" and operators[o1][1] <= operators[o2][1]) or (operators[o1][2] == "Right" and operators[o1][1] < operators[o2][1]))) do
          table.insert(queue, pop(stack))
          o2 = stack[#stack]
        end
        table.insert(stack, o1)
      elseif tokens[i] == '(' then
        table.insert(stack, tokens[i])
      elseif tokens[i] == ')' then
        while(stack[#stack] ~= "(") do
          table.insert(queue, pop(stack))
        end
        pop(stack)
      end
    end
    while #stack > 0 do
      table.insert(queue, pop(stack))
    end
    return queue
  end

  local tokens, solution = styard(str), {}

  for i=1,#tokens do
    local token = tokens[i]
    if token:find('%d') then
      table.insert(solution, token)
    else
      local o2, o1 = pop(solution), pop(solution)
      if token == "+" then
        table.insert(solution, o1+o2)
      elseif token == "-" then
        table.insert(solution, o1-o2)
      elseif token == "*" then
        table.insert(solution, o1*o2)
      elseif token == "/" then
        table.insert(solution, o1/o2)
      elseif token == "^" then
        table.insert(solution, o1^o2)
      end
    end
  end
  return solution[1]
end
