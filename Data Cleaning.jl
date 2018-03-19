using DataFrames

function searchdir(path,key)
    return string(path,"\\",filter(x->contains(x,key), readdir(path))[1])
end

function clean_order(Order)  #cleans up the batting order so that it is a number
    Order_clean =[];
    for order in Order
        if ~(typeof(order)==DataArrays.NAtype)
            if isa(parse(order), Number)
                order_clean = parse(order);
            else
                order_clean = 0;
            end
        else
            order_clean=0;
        end
        Order_clean = [Order_clean;order_clean];
    end
    return Order_clean;
end

function read_dfn_data(path_hitters,path_pitchers)
    # Load information for skaters table
    pitchers = readtable(path_pitchers);
    hitters = readtable(path_hitters);


    function clean_str(str)
        if str[1]=='@'
            return str[2:end];
        else
            return  str;
        end
    end

    Team = [pitchers[:Team]; hitters[:Team]];
    Opp=[pitchers[:Opp]; hitters[:Opp]];
    Game = [];
    for i = 1:size(Team)[1]
        t1 = clean_str(Team[i]);
        t2 = clean_str( Opp[i]);
        t = sort([t1,t2]);
        Game = [Game;string(t[1]," ",t[2])];
    end

    function clean_num(x)
        if isnan(x)
            return 0;
        else
            return  x;
        end
    end

    function cleannum(str)
      if str[1:end-1] == ""
        return 0.0
      else
        return parse(Float64, str[1:end-1])
      end
    end

    function adj_OBA(num)
      return -100*((num - .319)/.319)
    end

    pf=map(cleannum, [pitchers[:Park_Factor]; hitters[:Park_Factor]]);
    pitcher_oba_diff=map(cleannum, hitters[:Pitcher_wOBA_Diff]);
    hitter_oba_diff=map(cleannum, hitters[:Hitter_wOBA_Diff]);
    opp_oba=map(adj_OBA, pitchers[:Opponent_wOBA]);
    z=zeros(Float64, size(pitchers[:Opponent_wOBA]));
    vegas=map(cleannum, pitchers[:Vegas_Odds_Win]);
    z2=zeros(Float64, size(hitters[:Player_Name]));
    c=map(clean_num, [pitchers[:Ceil_FP]; hitters[:Ceil_FP]]);
    p=map(clean_num, [pitchers[:Proj_FP]; hitters[:Proj_FP]]);
    sfp=map(clean_num,[pitchers[:S_FP]; hitters[:S_FP]]);
    v=map(clean_num, [pitchers[:Variance]; hitters[:Variance]]);
    a=map(clean_num,[pitchers[:Actual_FP]; hitters[:Actual_FP]]);
    players = DataFrame(Player_Name = [pitchers[:Player_Name]; hitters[:Player_Name]],
                        Team = [pitchers[:Team]; hitters[:Team]],
                        Opp=[pitchers[:Opp] ;hitters[:Opp]],
                        Game = Game,
                        Pos=[pitchers[:Pos] ;hitters[:Pos]],
                        Salary=[pitchers[:Salary] ;hitters[:Salary]],
                        Ceiling=c,
                        S_FP=sfp,
                        Vegas=[vegas ;z2],
                        Park_Factor=pf,
                        Pitcher_wOBA_Diff=[opp_oba ;pitcher_oba_diff],
                        Hitter_wOBA_Diff=[z ;hitter_oba_diff],
                        Proj_FP=p,
                        Variance=v,
                        Actual_FP=a,
                        Batting_Order_Confirmed_ = [round(Int,zeros(size(pitchers)[1])); clean_order(hitters[:Batting_Order_Confirmed_])]
                        );

    return players;
end

# Output CSV file to upload to DraftKings
function createOutputcsvFromTracer(tracer, players, path_to_ID, P, C, oneB, twoB, threeB,SS,OF)
    # should be in format P P C 1B 2B 3B SS OF OF OF
    num_lineups = size(tracer)[2]
    num_players =size(tracer)[1]
    IDtable = readtable(path_to_ID)
    P_index = 1
    C_index = 3
    oneB_index = 4
    twoB_index = 5
    threeB_index = 6
    SS_index = 7
    OF_index = 8
    growinglineupMatrixWithID = "P,P,C,1B,2B,3B,SS,OF,OF,OF\n"
    for j = 1:num_lineups

        lineup = ["" "" "" "" "" "" "" "" "" ""]
        for i =1:num_players
            if tracer[i,j] == 1
                #println("\tlineup ", j," player ", i, ":", string(players[i,:Player_Name])," ",string(players[i,:Pos]))

                if P[i]==1
                    # if player i's position is P
                    if lineup[P_index]==""
                        lineup[P_index] = string(players[i,:Player_Name])
                    elseif lineup[P_index+1] ==""
                        lineup[P_index+1] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end

                elseif C[i]==1
                    if lineup[C_index]==""
                        lineup[C_index] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end
                elseif oneB[i]==1
                    if lineup[oneB_index]==""
                        lineup[oneB_index] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end
                elseif twoB[i]==1

                    if lineup[twoB_index]==""
                        lineup[twoB_index] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end
                elseif threeB[i]==1

                    if lineup[threeB_index]==""
                        lineup[threeB_index] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end
                elseif SS[i]==1

                    if lineup[SS_index]==""
                        lineup[SS_index] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end
                else
                    if OF[i] != 1
                        println(string("error in lineup",j,"player",i))
                    end

                    if lineup[OF_index]==""
                        lineup[OF_index] = string(players[i,:Player_Name])
                    elseif lineup[OF_index+1] ==""
                        lineup[OF_index+1] = string(players[i,:Player_Name])
                    elseif lineup[OF_index+2] ==""
                        lineup[OF_index+2] = string(players[i,:Player_Name])
                    else
                        println(string("error in lineup",j,"player",i))
                    end

                end

            end
            # end if tracer[i,j]==1 bracket

        end
        # end for i =1:num_players loop


        LineupOK = true
        lineupRowWithID =""
        #print("lineup ",j, ":",lineup,"\n")
        for name in lineup
            id = "FAIL"  #ID number of skater - keep it as FAIL if you CANNOT find a match in #the table
            for i =1:size(IDtable)[1]
                if lowercase(IDtable[i,:Name])== lowercase(name)
                    id = IDtable[i,:Name_ID]
                    #println(string("\tlineup ", j,", found ",name,"-- id = ",id))
                end
            end


            if !(id=="FAIL")
                lineupRowWithID = string(lineupRowWithID, id, ",")
            else
                LineupOK = false
                println("\n\t lineup ",j,", NOT FOUND: ",name,"\n")
            end
        end

        if LineupOK
            #println("\n\tlineup ",j," successfully created\n")
            lineupRowWithID = chop(lineupRowWithID)  #remove extra comma
            lineupRowWithID = string(lineupRowWithID,"\n")
            growinglineupMatrixWithID = string(growinglineupMatrixWithID,lineupRowWithID)
            #println(growinglineupMatrixWithID)
        end
    end


    outfile = open(path_to_output, "w")
    write(outfile, growinglineupMatrixWithID)
    close(outfile)



end

#this function merges the DFN pitcher and hitter files with the DK player ID file to give a
#table that you can use as input to the MIP
function merge_dk_dfn(path_hitters,path_pitchers,path_to_ID);
    dfn_players = read_dfn_data(path_hitters,path_pitchers);  #DFN player projections
    dk_players = readtable(path_to_ID);  #DK player IDs for the games of the contest
    nplayers = size(dk_players)[1]  #number of players in the DK contest
    i_dfn =0
    dfn_delete_names =[]
    for dfn_name in dfn_players[:,:Player_Name]
        i_dfn = i_dfn+1;  #index for dfn table
        dfn_team = dfn_players[i_dfn,:Team]
        dfn_pts = dfn_players[i_dfn,:Proj_FP]
        id = "FAIL"  #ID number of skater - keep it as FAIL if you CANNOT find a match in #the table
        i=0
        for dk_name in dk_players[:,:Name]
            i=i+1;  #update the counter in the dk_players table for when we find matchin ID
            dk_team = dk_players[i,:TeamAbbrev];
            if (lowercase(dk_name)== lowercase(dfn_name)) & (lowercase(dk_team)== lowercase(dfn_team)) & (dfn_pts>0)
                if dfn_pts<=0
                    println(dfn_name," ",dk_team," ", dfn_team," ", dfn_pts, " predicted points")
                end
                id = dk_players[i,:Name_ID]
            end
        end

        if id=="FAIL"
            dfn_delete_names=[dfn_delete_names;dfn_name];
        end
    end
    for dfn_name in dfn_delete_names
        deleterows!(dfn_players,find(dfn_players[:,:Player_Name].==dfn_name));
    end
    return(dfn_players)
end

### Similar to the above function, filters the covariance file so it has the same dimensions as the players matrix

function merge_dk_cov(cov,path_hitters,path_pitchers,path_to_ID)
  cov_players = readtable(cov)
  pitchers = readtable(path_pitchers)
  hitters = readtable(path_hitters)
  dfn_players = read_dfn_data(path_hitters,path_pitchers)
  dk_players = readtable(path_to_ID)

  players_cov = DataFrame(Name = [pitchers[:Player_Name];cov_players[:Name]])
  psize = size(pitchers[:Player_Name])[1]

  for i = 1:size(players_cov[:Name])[1]
    if i <= psize
      players_cov = hcat(players_cov, zeros(size(players_cov[:Name])[1]))

    else
      z = zeros(psize)
      b = cov_players[i - psize + 1]
      players_cov = hcat(players_cov, [z; b])
    end
  end

  ind1 = 0
  delete_rows = []
  for name in players_cov[:Name]
      ind1 += 1
      pts = dfn_players[ind1, :Proj_FP]
      team = dfn_players[ind1, :Team]

      ind2 = 0
      id = "Fail"
      for dkname in dk_players[:Name]
        ind2 += 1
        dkteam = dk_players[ind2, :TeamAbbrev]

        if (lowercase(dkname) == lowercase(name)) & (lowercase(dkteam) == lowercase(team)) & (pts > 0)
          id = "Pass"
        end
      end

      if id == "Fail"
        delete_rows = push!(delete_rows, name)
      end
  end

  for n in delete_rows
      row_num = find(players_cov[:Name].==n)
      col_num = row_num + 1
      deleterows!(players_cov, row_num)
      delete!(players_cov, col_num)
  end

  return(players_cov)
end












########################

#folder = "2016-05-22\\"  #folder where the player projections are

#path to the csv file with the players information (pitchers and hitters)
#path_pitchers = string(folder,"dailyfantasynerd_players (1).csv");
#path_hitters = string(folder,"dailyfantasynerd_players.csv");
#path_to_ID = string(folder,"DKSalaries.csv");

#players_dfn = read_dfn_data(path_hitters,path_pitchers);
#players_dk = readtable(path_to_ID);
#x = merge_dk_dfn(path_hitters,path_pitchers,path_to_ID);
