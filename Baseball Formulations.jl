#=
This code implements the No Stacking baseball
=#

# To install DataFrames, simply run Pkg.add("DataFrames")
using DataFrames

# To install MathProgBase, simply run Pkg.add("MathProgBase")
using MathProgBase

include("Data Cleaning.jl")
#=
GLPK is an open-source solver, and additionally Cbc is an open-source solver. This code uses GLPK
because we found that it was slightly faster than Cbc in practice. For those that want to build
very sophisticated models, they can buy Gurobi. To install GLPKMathProgInterface, simply run
Pkg.add("GLPKMathProgInterface")
=#
using GLPKMathProgInterface
using Gurobi
# Once again, to install run Pkg.add("JuMP")
using JuMP



#####################################################################################################################
#####################################################################################################################
# This is a function that creates one lineup using the No Stacking formulation from the paper
function one_lineup_best(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,nstacks)

    m = Model(solver=GLPKSolverMIP())

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    # 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    # Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)

    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    # at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    # Overlap Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap)

    # Objective
    @objective(m, Max, sum{players[i,:Actual_FP]*players_lineup[i], i=1:num_players})



    # Solve the integer programming problem
    println("Solving Problem...")
    @printf("\n")
    status = solve(m);


    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end
#####################################################################################################################
#####################################################################################################################
# This is a function that creates one lineup using the No Stacking formulation from the paper
function one_lineup_stacking_type_0(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,nstacks)
    num_teams = 2*num_games
 	m = Model(solver=GLPKSolverMIP())

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    # 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    # Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)

    #  2 P constraint
	@constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
	@constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
	# one B2 constraint
	@constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
	# one B3 constraint
	@constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
	# one C constraint
	@constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
	# one SS constraint
	@constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
	# 3 OF constraint
	@constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    # at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)

    #at most 5 hitters from one team constraint
    @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)


    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])

	# Objective
    @objective(m, Max, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players})



    # Solve the integer programming problem
    println("Solving Problem...")
    @printf("\n")
    status = solve(m);


    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end


#####################################################################################################################
#####################################################################################################################
# This is a function that creates one lineup using the  Stacking Type 1 formulation
# No pitcher opposite batter
function one_lineup_stacking_type_1(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,nstacks)

    num_teams = 2*num_games
    m = Model(solver=GLPKSolverMIP())

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    # 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    # Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)

    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    # at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])

    # Objective
    @objective(m, Max, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players})

    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)

    # Solve the integer programming problem
    println("Solving Problem...")
    @printf("\n")
    status = solve(m);


    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end


#####################################################################################################################
#####################################################################################################################
#
function stacking_non_consecutive_projections(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,nstacks)

    num_teams = 2*num_games
    m = Model(solver=GurobiSolver(OutputFlag=0))
    print(size(players))
    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    # 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    # Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)

    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    # at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])

    #at most 5 hitters from one team constraint
    # @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)

    # Objective
    @objective(m, Max, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players})
    #println(players_lineup)
    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)
    #at least b1 batters from at least n1 teams

    # b1 = stack_order[1]  #number of batters on first stack
    # n1 = nstacks[1]  #number of teams that have first stack count
    # b2 =  stack_order[2]
    # n2 = nstacks[2]
    # @variable(m, used_team_batters[i=1:num_teams], Bin)
    # @constraint(m, constr[i=1:num_teams], b1*used_team_batters[i] <= sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players})
    # @constraint(m, sum{used_team_batters[i], i=1:num_teams} >= n1)

    # STACKING CONSTRAINT -- NON CONSECUTIVE BATTERS
    @variable(m, used_team[i=1:num_teams], Bin)
    @constraint(m, constr_stack[i=1:num_teams], used_team[i]*stack_order[1] <= sum{players_teams[t,i]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_team[i], i=1:num_teams} >= 1)
    #@constraint(m, sum{used_team[i]*sum{players_teams[t,i]*(1-P[t])*players_lineup[t], t=1:num_players}, i=1:num_teams} >= stack_order[1])



	# #at least b2 batters from at least n2 teams
  #   @variable(m, used_team_batters1[i=1:num_teams], Bin)
  #   @constraint(m, constr1[i=1:num_teams], b2*used_team_batters1[i] <= sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players})
  #   @constraint(m, sum{used_team_batters1[i], i=1:num_teams} >= n2)


    #limit pitchers budget
	#@constraint(m, sum{players[i,:Salary]*players_lineup[i]*P[i], i=1:num_players}>= 15000)


	########################################################################################################
    # Solve the integer programming problem
    println("\tSolving Problem...")
    @printf("\n")
    status = solve(m);

    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end

function stacking_non_consecutive_variance(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,nstacks)

    num_teams = 2*num_games
    m = Model(solver=GurobiSolver(OutputFlag=0))

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    # 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    # Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}>= 45000)

    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    # at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])

    #at most 5 hitters from one team constraint
    # @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)

    # Objective
    @objective(m, Max, sum{players[i,:Variance]*players_lineup[i], i=1:num_players})

    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)
    #at least b1 batters from at least n1 teams
    num_teams = 2*num_games
    # b1 = stack_order[1]  #number of batters on first stack
    # n1 = nstacks[1]  #number of teams that have first stack count
    # b2 =  stack_order[2]
    # n2 = nstacks[2]
    # @variable(m, used_team_batters[i=1:num_teams], Bin)
    # @constraint(m, constr[i=1:num_teams], b1*used_team_batters[i] <= sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players})
    # @constraint(m, sum{used_team_batters[i], i=1:num_teams} >= n1)

    # STACKING CONSTRAINT -- NON CONSECUTIVE BATTERS
    @variable(m, used_team[i=1:num_teams], Bin)
    @constraint(m, constr_stack[i=1:num_teams], used_team[i]*stack_order[1] <= sum{players_teams[t,i]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_team[i], i=1:num_teams} >= 1)


	# #at least b2 batters from at least n2 teams
  #   @variable(m, used_team_batters1[i=1:num_teams], Bin)
  #   @constraint(m, constr1[i=1:num_teams], b2*used_team_batters1[i] <= sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players})
  #   @constraint(m, sum{used_team_batters1[i], i=1:num_teams} >= n2)


    #limit pitchers budget
	#@constraint(m, sum{players[i,:Salary]*players_lineup[i]*P[i], i=1:num_players}>= 15000)


	########################################################################################################
    # Solve the integer programming problem
    println("\tSolving Problem...")
    @printf("\n")
    status = solve(m);


    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end

#####################################################################################################################
#####################################################################################################################
# This is a function that creates one lineup using the  Stacking Type 3 formulation
# No pitcher opposite batter
# Batters with consecutive batting order
function projection(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,num_stacks)

    num_teams = 2*num_games
    num_stacks = 9;  #number of stacks per team (this is 9)

    #m = Model(solver=GLPKSolverMIP())
    m = Model(solver=GurobiSolver(OutputFlag=0))

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    #NUMBER OF PLAYERS 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    #SALARY: Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)
    # @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}>= 45000)


    #OBJECTIVE
    # @constraint(m, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players}>=95)
    @objective(m, Max, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players})


    #POSITION
    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    #GAMES: at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #at most 5 hitters from one team constraint
    @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)



    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])


    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)

    #NO PITCHER VS PITCHER constraint
    @constraint(m,pitcher_pithcher[g=1:num_games],sum{P[p]*players_lineup[p]*players_games[p,g],p=1:num_players}<=1)

    #STACK: at least stack_order batters from at least nstack teams, consecutive hitting order
    #stack_order = [4,2];  #sizes of the stacks
    nstacks = [1,1]  #number of teams that have first stack count

    @variable(m, used_stack_batters1[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack1[i=1:num_teams,j=1:num_stacks], stack_order[1]*used_stack_batters1[i,j] <=
                   sum{players_teams[t, i]*players_stacks1[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters1[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[1])

	@variable(m, used_stack_batters2[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack2[i=1:num_teams,j=1:num_stacks], stack_order[2]*used_stack_batters2[i,j] <=
                   sum{players_teams[t, i]*players_stacks2[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters2[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[2])



	########################################################################################################
    # Solve the integer programming problem
    println("\tSolving Problem...")
    @printf("\n")

    tic()
    status = solve(m);
    telapsed = toq();
    println("\t took ", telapsed, " sec")

    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end

###############################################################################
###############################################################################

# Variance formulation
# Identical to one_lineup_stacking_type_3 but optimizes variance and sets lower bound on salary

function variance_covariance(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,num_stacks,players_cov)

    num_teams = 2*num_games
    num_stacks = 9;  #number of stacks per team (this is 9)

    #m = Model(solver=GLPKSolverMIP())
    m = Model(solver=GurobiSolver(OutputFlag=0))

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    #NUMBER OF PLAYERS 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    #SALARY: Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}>= 45000)

    #PROJECTED POINTS: Min proj point contstraint

    #OBJECTIVE

    @constraint(m, sum{players[i,:Park_Factor]*players_lineup[i], i=1:num_players}>=-20)
    @constraint(m, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players}>=85)

    #@objective(m, Max, sum{players[i,:Variance]*players_lineup[i], i=1:num_players})

    #POSITION
    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    #GAMES: at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #at most 5 hitters from one team constraint
    @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)



    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])

    #player lineup limit constraint
    lineup_count = sum(lineups,2)  #count of previous lineups of players



    # @constraint(m, constr[i=1:num_players], players_lineup[i] +lineup_count[i]<=50);

    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)


    #NO PITCHER VS PITCHER constraint
    @constraint(m,pitcher_pithcher[g=1:num_games],sum{P[p]*players_lineup[p]*players_games[p,g],p=1:num_players}<=1)

    #Covariance matrix -> matches each team stack order with the sum of its non-diagonal covariance matrix entries

    @variable(m, stack_cov[i=1:num_teams,j=1:num_stacks])

    for i=1:num_teams, j=1:num_stacks
      ind = []
      for k=1:num_players
        if players_stacks1[k,j]*players_teams[k,i]*(1-P[k]) == 1
          ind = push!(ind, k)
        end
      end

      cov_ij = 0
      for p1 in ind, p2 in ind
        if p1 != p2
          cov_ij += players_cov[p1, p2 + 1]
        end
      end
      @constraint(m, stack_cov[i,j] == cov_ij)

    end

    #STACK: at least stack_order batters from at least nstack teams, consecutive hitting order
    #stack_order = [4,2];  #sizes of the stacks
    #nstacks = [1,1]  #number of teams that have first stack count
    @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=stack_order[1])


    @variable(m, used_stack_batters1[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack1[i=1:num_teams,j=1:num_stacks], stack_order[1]*used_stack_batters1[i,j] <=
                   sum{players_teams[t, i]*players_stacks1[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters1[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[1])

	  @variable(m, used_stack_batters2[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack2[i=1:num_teams,j=1:num_stacks], stack_order[2]*used_stack_batters2[i,j] <=
                   sum{players_teams[t, i]*players_stacks2[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters2[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[2])


    @objective(m, Max, var_weight*sum{players[i,:Variance]*players_lineup[i], i=1:num_players} +
    mean_weight*sum{(players[i,:Proj_FP]^2)*players_lineup[i], i=1:num_players} +
    cov_weight*sum{used_stack_batters1[i,j]*stack_cov[i,j], i=1:num_teams, j=1:num_stacks})



	########################################################################################################
    # Solve the integer programming problem
    println("\tSolving Problem...")
    @printf("\n")

    tic()
    status = solve(m);
    telapsed = toq();
    println("\t took ", telapsed, " sec")

    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        #println("Objective value is ", getobjectivevalue(m))
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end

end


function variance(players, lineups, num_overlap, num_players, num_games,P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2, stack_order,num_stacks)

    num_teams = 2*num_games
    num_stacks = 9;  #number of stacks per team (this is 9)

    #m = Model(solver=GLPKSolverMIP())
    m = Model(solver=GurobiSolver(OutputFlag=0))

    # Variable for players in lineup.
    @variable(m, players_lineup[i=1:num_players], Bin)

    #NUMBER OF PLAYERS 10 players constraint
    @constraint(m, sum{players_lineup[i], i=1:num_players} == 10)

    #SALARY: Financial Constraint
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}<= 50000)
    # @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}>= 45000)


    #OBJECTIVE
    # @constraint(m, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players}>=95)
    @objective(m, Max, sum{players[i,:Variance]*players_lineup[i], i=1:num_players})
    @constraint(m, sum{players[i,:Salary]*players_lineup[i], i=1:num_players}>= 45000)

    #PROJECTED POINTS: Min proj point contstraint

    #OBJECTIVE

    @constraint(m, sum{players[i,:Park_Factor]*players_lineup[i], i=1:num_players}>=-20)
    @constraint(m, sum{players[i,:Proj_FP]*players_lineup[i], i=1:num_players}>=85)


    #POSITION
    #  2 P constraint
    @constraint(m, sum{P[i]*players_lineup[i], i=1:num_players}==2)
    # one B1 constraint
    @constraint(m, sum{B1[i]*players_lineup[i], i=1:num_players}==1)
    # one B2 constraint
    @constraint(m, sum{B2[i]*players_lineup[i], i=1:num_players}==1)
    # one B3 constraint
    @constraint(m, sum{B3[i]*players_lineup[i], i=1:num_players}==1)
    # one C constraint
    @constraint(m, sum{C[i]*players_lineup[i], i=1:num_players}==1)
    # one SS constraint
    @constraint(m, sum{SS[i]*players_lineup[i], i=1:num_players}==1)
    # 3 OF constraint
    @constraint(m, sum{OF[i]*players_lineup[i], i=1:num_players}==3)




    #GAMES: at least 2 different games for the 10 players constraints
    @variable(m, used_game[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games], used_game[i] <= sum{players_games[t, i]*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_game[i], i=1:num_games} >= 2)


    #at most 5 hitters from one team constraint
    @constraint(m, constr[i=1:num_teams], sum{players_teams[t, i]*(1-P[t])*players_lineup[t], t=1:num_players}<=5)



    #OVERLAP Constraint
    @constraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*players_lineup[j], j=1:num_players} <= num_overlap[i])


    #NO PITCHER VS BATTER no pitcher vs batter constraint
    @constraint(m, hitter_pitcher[g=1:num_teams],
                   8*sum{P[k]*players_lineup[k]*players_teams[k,g],k=1:num_players} +
                    sum{(1-P[k])*players_lineup[k]*players_opp[k,g], k=1:num_players}<=8)

    #NO PITCHER VS PITCHER constraint
    @constraint(m,pitcher_pithcher[g=1:num_games],sum{P[p]*players_lineup[p]*players_games[p,g],p=1:num_players}<=1)

    #STACK: at least stack_order batters from at least nstack teams, consecutive hitting order
    #stack_order = [4,2];  #sizes of the stacks
    nstacks = [1,1]  #number of teams that have first stack count

    @variable(m, used_stack_batters1[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack1[i=1:num_teams,j=1:num_stacks], stack_order[1]*used_stack_batters1[i,j] <=
                   sum{players_teams[t, i]*players_stacks1[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters1[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[1])

	@variable(m, used_stack_batters2[i=1:num_teams,j=1:num_stacks], Bin)
    @constraint(m, constr_stack2[i=1:num_teams,j=1:num_stacks], stack_order[2]*used_stack_batters2[i,j] <=
                   sum{players_teams[t, i]*players_stacks2[t, j]*(1-P[t])*players_lineup[t], t=1:num_players})
    @constraint(m, sum{used_stack_batters2[i,j], i=1:num_teams,j=1:num_stacks} >= nstacks[2])



	########################################################################################################
    # Solve the integer programming problem
    println("\tSolving Problem...")
    @printf("\n")

    tic()
    status = solve(m);
    telapsed = toq();
    println("\t took ", telapsed, " sec")

    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        players_lineup_copy = Array(Int64, 0)
        for i=1:num_players
            if getvalue(players_lineup[i]) >= 0.9 && getvalue(players_lineup[i]) <= 1.1
                players_lineup_copy = vcat(players_lineup_copy, fill(1,1))
            else
                players_lineup_copy = vcat(players_lineup_copy, fill(0,1))
            end
        end

        return(players_lineup_copy)
    end
end
