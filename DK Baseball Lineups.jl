#=
This code implements the stacking for DK baseball
=#

# To install DataFrames, simply run Pkg.add("DataFrames")
using DataFrames

# To install MathProgBase, simply run Pkg.add("MathProgBase")
using MathProgBase

include("Data Cleaning.jl")
include("Baseball Formulations.jl")  #this code has all the different formualations
# include("Variance Compiler.jl") #this code compiles variances for each player
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
function create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks)
    #=
    num_lineups is an integer that is the number of lineups
    num_overlap is an integer that gives the overlap between each lineup
    path_pitchers,path_hitters is a string that gives the path to the players csv file
    formulation is the type of formulation you would like to use (for instance one_lineup_Type_1, one_lineup_Type_2, etc.)
    path_to_output is a string where the final csv file with your lineups will be
    =#

    println("loading data")
    players = merge_dk_dfn(path_hitters,path_pitchers,path_to_ID);


    # Number of players
    num_players = size(players)[1]

    # Create team indicators from the information in the players file
    teams = unique(players[:Team])
    num_teams = size(teams)[1]
    println(num_teams," teams playing tonight")

    # Create team indicators from the information in the players file
    games = unique(players[:Game])
    num_games = size(games)[1]
    println(num_games," games playing tonight")


    # arrays that store the information on which players are which position
    P = Array(Int64, 0);
    B1 = Array(Int64, 0);
    B2 =Array(Int64, 0);
    B3 =Array(Int64, 0);
    C =Array(Int64, 0);
    SS=Array(Int64, 0);
    OF=Array(Int64, 0);
    RP=Array(Int64, 0);


    #=
    Process the position information in the skaters file to populate the position and order
    #arrays  with the corresponding correct information
    =#
    for i =1:num_players
        pos = players[i,:Pos];
        #print(players[i,:Player_Name]," ",pos,"\n")
        if contains(pos,"SP")
            P=vcat(P,fill(1,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))


        elseif contains(pos,"RP")
            P=vcat(P,fill(0,1))
            RP=vcat(RP,fill(1,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))

        elseif contains(pos,"1B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(1,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"2B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(1,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"3B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(1,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"C")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(1,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"SS")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(1,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"OF")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(1,1))
            RP=vcat(RP,fill(0,1))

        else
            println("\t",players[i,:Player_Name]," has no position\n")

        end
    end


    #GAMES:   player_info stores information on which game each player is on
    player_info = zeros(Int, num_games)

    # Populate player_info with the corresponding information
    for j=1:num_games
        if players[1, :Game] == games[j]
            player_info[j] =1
        end
    end
    players_games = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_games)
        for j=1:num_games
            if players[i, :Game] == games[j]
                player_info[j] =1
            end
        end
        players_games = vcat(players_games, player_info')
    end

    #TEAMS:   player_info stores information on which team each player is on
    player_info = zeros(Int, num_teams)

    # Populate player_info with the corresponding information
    for j=1:size(teams)[1]
        if players[1, :Team] == teams[j]
            player_info[j] =1
        end
    end
    players_teams = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_teams)
        for j=1:size(teams)[1]
            if players[i, :Team] == teams[j]
                player_info[j] =1
            end
        end
        players_teams = vcat(players_teams, player_info')
    end

    #OPPONENT TEAM player_info stores information on which team each player is opposing
    player_info = zeros(Int, num_teams)

    # Populate player_info with the corresponding information
    for j=1:num_teams
        if players[1, :Opp][1]=='@'
            opp = players[1, :Opp][2:end]
        else
            opp = players[1, :Opp]
        end

        if opp == teams[j]
            player_info[j] =1
        end
    end
    players_opp = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_teams)
        for j=1:size(teams)[1]
            if players[i, :Opp][1]=='@'
                opp = players[i, :Opp][2:end]
            else
                opp = players[i, :Opp]
            end
            if opp == teams[j]
                player_info[j] =1
            end
        end
        players_opp = vcat(players_opp, player_info')
    end

    #STACK player_info stores information on which team each player is on
    num_stacks = 9;  #number of stacks

    #make matrix for 1st stacking (stacking_order[1])
    player_info = zeros(Int,num_stacks);

    # Populate player_info with the corresponding information, start with the first player to initiate the array
    for j=1:num_stacks #5, 6, 4
        if players[1,:Batting_Order_Confirmed_] == j
            stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[1]];  #index of the stacks this batting order belongs to.
            #For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
            for k in stack_ind
                player_info[k]=1;
            end
        end
    end
    players_stacks1 = player_info';

    #now update the stack matrix of players 2 to num_players
    for i=2:num_players
        player_info = zeros(Int,num_stacks);
        for j=1:num_stacks
            if players[i,:Batting_Order_Confirmed_] == j
                stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[1]];  #index of the stacks this batting order belongs to.
                #For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
                for k in stack_ind
                    player_info[k]=1;
                end
            end
        end
        players_stacks1 = vcat(players_stacks1, player_info');
    end

    #make matrix for 2nd stacking (stacking_order[2])
    player_info = zeros(Int,num_stacks);

    # Populate player_info with the corresponding information, start with the first player to initiate the array
    for j=1:num_stacks
        if players[1,:Batting_Order_Confirmed_] == j
            stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[2]];  #index of the stacks this batting order belongs to.
            #For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
            for k in stack_ind
                player_info[k]=1;
            end
        end
    end
    players_stacks2 = player_info';

    #now update the stack matrix of players 2 to num_players
    for i=2:num_players
        player_info = zeros(Int,num_stacks);
        for j=1:num_stacks
            if players[i,:Batting_Order_Confirmed_] == j
                stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[2]];  #index of the stacks this batting order belongs to.
                #For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
                for k in stack_ind
                    player_info[k]=1;
                end
            end
        end
        players_stacks2 = vcat(players_stacks2, player_info');
    end


    ###########################################################################
    #my formulation is:  formulation(players, old_lineups, num_overlap, num_players, num_games, P,B1,B2,B3,C,SS,OF,
    #                                 players_teams, players_opp, players_games,players_stacks1,players_stacks2,
    #                                 stack_order,nstacks)

    # Lineups using formulation as the stacking type
    println("Calculating lineup 1 of ", num_lineups)

    the_lineup  = formulation(players, hcat(zeros(Int, num_players), zeros(Int, num_players)), num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
                              stack_order,nstacks)

    println("Calculating lineup 2 of ", num_lineups)

    the_lineup2 = formulation(players, hcat(the_lineup, zeros(Int, num_players)), num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
                             stack_order,nstacks)

    tracer = hcat(the_lineup, the_lineup2)
    for i=1:(num_lineups-2)
        println("Calculating lineup ", i+2, " of ", num_lineups)
        try
            thelineup = formulation(players, tracer, num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
                              stack_order,nstacks)
            tracer = hcat(tracer,thelineup)
        catch
            print("some optimization error")
            break
        end
    end

 	createOutputcsvFromTracer(tracer, players, path_to_ID, P, C, B1, B2, B3,SS,OF)
end




###############################################################################
###############################################################################
###############################################################################
###############################################################################
#INPUT PARAMS
folder = "C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/2016.7.20\\"  #folder where the player projections are - this folder is named by the date of the contest

num_lineups = 150; # num_lineups is the total number of lineups
n0_overlap = 150;
num_overlap =[6*ones(n0_overlap,1); 7*ones(num_lineups-n0_overlap,1)];
# num_overlap is the maximum overlap of players between the lineups
stack_order = [4,1]; #order of each stack you want
nstacks = [1,1];  #number of teams with each stack order

#FORMULATION:  formulation is the type of formulation that you would like to use.
    #formulation = one_lineup_best  #use actual points
    #formulation = one_lineup_stacking_type_0   #use proj pts,no stacking
    #formulation = one_lineup_stacking_type_1  #use proj pts, no hitters vs pitcher (nhvp)
    #formulation = one_lineup_stacking_type_2 #use proj pts, nhvp, hitters from one team
    #formulation = one_lineup_stacking_type_3 #use proj pts, nhvp, hitters from one team, consecutive batting order

formulation = variance

path_pitchers = string(folder,"dailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters);
path_hitters = string(folder,"dailyfantasynerd_players.csv");

path_to_ID= searchdir(folder,"DKSalaries");
path_to_output= string(folder,"7.19_", string(formulation), "_stack", stack_order[1], "_overlap_", num_overlap[1],"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results
print(path_to_output);

#########################################################################
# Running the code
println("Calculating DraftKings baseball linueps.\n ", num_lineups, " lineups\n","Stack type ",formulation,
"\nOverlap = ", num_overlap[1],"\n" )

tic()
create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks)
telapsed = toq();

println("Calculated DraftKings baseball lineups.\n ", num_lineups, " lineups\n","Stack type ",formulation,
"\nOverlap = ", num_overlap[1],"\n" )
println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")
println("Saving data to file ",path_to_output,"\nDK Mafia 4 life")
