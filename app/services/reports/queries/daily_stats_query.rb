# frozen_string_literal: true

module Reports
  module Queries
    # rubocop:disable Metrics/ClassLength
    class DailyStatsQuery < ApplicationService
      def call
        ActiveRecord::Base.connection.execute(daily_stats_query).to_a.first
      end

      private

      def daily_stats_query
        <<~SQL
          select
          	c.dayDate,
          	c.ftd_count,
          	c.real_money_ftd,
          	c.bonus_money_ftd,
          	coalesce(c.all_live_bets + all_prematch_bets, 0) as total_bets,
          	coalesce(c.all_live_wins + all_prematch_wins, 0) as total_wins,
          	coalesce((c.all_live_bets + all_prematch_bets) - (c.all_live_wins + all_prematch_wins), 0) as ggr,
          	coalesce(c.pending_bets) as pending_bets,
          	coalesce(c.deposit, 0) as deposits,
          	coalesce(c.withdraw, 0) as withdrawals,
          	coalesce(c.diff_depvs_with, 0) as deposits_minus_withdrawals,
          	c.unique_bettors as unique_bettors,
          	coalesce(c.bonus_granted, 0) as bonus_granted,
          	coalesce(c.avg_deposit, 0) as avg_deposit,
          	coalesce(c.amt_of_failed_deposits, 0) as amt_of_failed_deposits,
          	coalesce(c.all_live_bets, 0) as all_live_bets,
          	coalesce(c.avg_live_bet, 0) as avg_live_bet,
          	coalesce(c.all_prematch_bets, 0) as all_prematch_bets,
          	coalesce(c.avg_prematch_bet, 0) as avg_prematch_bet,
          	coalesce(c.all_prematch_wins, 0) as all_prematch_wins,
          	coalesce(c.all_live_wins, 0) as all_live_wins,
          	case
          		when c.all_live_bets = 0 then c.all_live_wins
          		else c.all_live_wins / c.all_live_bets
          	end as hold_live,
          	case
          		when c.all_prematch_bets = 0 then c.all_prematch_wins
          		else c.all_prematch_wins / c.all_prematch_bets
          	end as hold_prematch,
          	case
          		when all_live_bets + all_prematch_bets = 0 then all_live_wins + all_prematch_wins
          		else (all_live_wins + all_prematch_wins) / (all_live_bets + all_prematch_bets)
          	end as hold_overall
          from
          	(
          	select
          		to_char(b.dayDate, 'YYYY-MM-DD') as dayDate,
          		sum(b.ftd_count) as ftd_count,
          		sum(b.real_money_ftd) as real_money_ftd,
          		sum(b.bonus_money_ftd) as bonus_money_ftd,
          		sum(b.balance_eur) as balance_eur,
          		coalesce(sum(b.deposit), 0) as deposit,
          		coalesce(sum(b.deposit_count), 0) as deposit_count,
          		sum(b.deposit) / sum(b.deposit_count) as avg_deposit,
          		count(distinct(b.bettors)) as unique_bettors,
          		sum(b.bonus_granted) as bonus_granted,
          		coalesce(sum(b.withdraw), 0) as withdraw,
          		coalesce(sum(b.deposit), 0) - coalesce(sum(b.withdraw), 0) as diff_depvs_with,
          		coalesce(sum(b.faileddeposit), 0) as faileddeposit,
          		coalesce(sum(b.faileddeposit_count), 0) as amt_of_failed_deposits,
          		coalesce(sum(b.all_live_bets), 0) as all_live_bets,
          		coalesce(sum(b.live_bet_count), 0) as live_bet_count,
          		sum(b.all_live_bets) / sum(b.live_bet_count) as avg_live_bet,
          		coalesce(sum(b.all_prematch_bets), 0) as all_prematch_bets,
          		sum(b.prematch_bet_count) as prematch_bet_count,
          		sum(b.all_prematch_bets) / sum(b.prematch_bet_count) as avg_prematch_bet,
          		coalesce(sum(b.all_live_wins), 0) as all_live_wins,
          		coalesce(sum(b.all_prematch_wins), 0) as all_prematch_wins,
          		coalesce(sum(b.pending_bets), 0) as pending_bets,
          		coalesce(sum(b.pending_bets), 0) * sum(b.odds) as liability
          	from
          		(
          		select
          			case
          				when a.dayDate2 is null then a.dayDate
          				else a.dayDate2
          			end as dayDate,
          			a.real_money_ftd,
          			case
          				when a.real_money_ftd > 0 then 1
          			end as ftd_count,
          			a.bonus_money_ftd,
          			a.bettors,
          			a.balance_eur,
          			a.deposit as deposit,
          			case
          				when a.deposit > 0 then 1
          			end as deposit_count,
          			a.bonus_granted as bonus_granted,
          			a.withdraw as withdraw,
          			case
          				when a.withdraw > 0 then 1
          			end as withdraw_count,
          			a.faileddeposit as faileddeposit,
          			case
          				when a.faileddeposit > 0 then 1
          			end as faileddeposit_count,
          			case
          				when a.type_of_bet = 'Live'
          				or a.type_of_rolledbackbet = 'Live' then (a.real_money_bet + a.bonus_money_bet) - (a.rolledback_bonus_bet + a.rolledback_real_money_bet)
          			end as all_live_bets,
          			case
          				when a.type_of_bet = 'Live' then 1
          				when a.type_of_rolledbackbet = 'Live' then -1
          			end as live_bet_count,
          			case
          				when a.type_of_bet = 'Prematch'
          				or a.type_of_rolledbackbet = 'Prematch' then (a.real_money_bet + a.bonus_money_bet) - (a.rolledback_bonus_bet + a.rolledback_real_money_bet)
          			end as all_prematch_bets,
          			case
          				when a.type_of_bet = 'Prematch' then 1
          				when a.type_of_rolledbackbet = 'Prematch' then -1
          			end as prematch_bet_count,
          			case
          				when a.type_of_win = 'Live'
          				or a.type_of_rolledbackwin = 'Live' then (a.real_money_win + a.bonus_money_win) - (a.rolledback_bonus_win + a.rolledback_real_money_win)
          			end as all_live_wins,
          			case
          				when a.type_of_win = 'Prematch'
          				or a.type_of_rolledbackwin = 'Prematch' then (a.real_money_win + a.bonus_money_win) - (a.rolledback_bonus_win + a.rolledback_real_money_win)
          			end as all_prematch_wins,
          			a.pending_real_money_bet + a.pending_bonus_money_bet as pending_bets,
          			a.odd_value as odds
          		from
          			(
          			select
          				ent.id,
          				case
          					when bet.dayDate is null then ent.dayDate
          					else bet.dayDate
          				end as dayDate,
          				case
          					when pending.dayDate is not null then current_date-1
          				end as dayDate2,
          				ent.customer_id,
          				ftdtable.real_money_ftd,
          				ftdtable.bonus_money_ftd,
          				bet.customer_id as bettors,
          				ent.b_tag,
          				balance.balance_eur,
          				succesfuldeposit.deposit,
          				succesfuldeposit.bonus_granted,
          				-withdraw.withdraw as withdraw,
          				unsuccesfuldeposit.faileddeposit,
          				bet.betid,
          				bet.bet_type as type_of_bet,
          				coalesce(bet.real_money_bet, 0) as real_money_bet,
          				coalesce(bet.bonus_money_bet, 0) as bonus_money_bet,
          				win.bet_type as type_of_win,
          				coalesce(win.real_money_win, 0) as real_money_win,
          				coalesce(win.bonus_money_win, 0) as bonus_money_win,
          				rolledbackwin.bet_type as type_of_rolledbackwin,
          				coalesce(rolledbackwin.rolledback_bonus_win, 0) as rolledback_bonus_win,
          				coalesce(rolledbackwin.rolledback_real_money_win, 0) as rolledback_real_money_win,
          				rolledbackbet.bet_type as type_of_rolledbackbet,
          				coalesce(rolledbackbet.rolledback_bonus_bet, 0) as rolledback_bonus_bet,
          				coalesce(rolledbackbet.rolledback_real_money_bet, 0) as rolledback_real_money_bet,
          				coalesce(pending.pending_real_money_bet, 0) as pending_real_money_bet,
          				coalesce(pending.pending_bonus_money_bet, 0) as pending_bonus_money_bet,
          				pending.odd_value
          			from
          				(
          				select
          					er.id,
          					c.b_tag as b_tag,
          					er.status,
          					er.created_at as dayDate,
          					er.customer_id,
          					er.kind,
          					er.mode,
          					er.origin_type,
          					er.origin_id
          				from
          					entry_requests er
          				join customers c on
          					c.id = er.customer_id ) ent
          			left join (
          				select
          					er.id as entry_request_id,
          					e.created_at as dayDate,
          					e.base_currency_real_money_amount as deposit,
          					e.base_currency_bonus_amount as bonus_granted
          				from
          					entry_requests er
          				left join entries e on
          					er.id = e.entry_request_id
          				where
          					er.kind = 'deposit'
          					and er.status = 'succeeded'
          					and er.mode != 'cashier') succesfuldeposit on
          				ent.id = succesfuldeposit.entry_request_id
          			left join (
          				select
          					er.id as entry_request_id,
          					e.created_at as dayDate,
          					e.base_currency_real_money_amount as withdraw
          				from
          					entry_requests er
          				left join entries e on
          					er.id = e.entry_request_id
          				where
          					er.kind = 'withdraw'
          					and er.status = 'succeeded'
          					and confirmed_at is not null) withdraw on
          				ent.id = withdraw.entry_request_id
          			left join (
          				select
          					er.id as entry_request_id,
          					er.created_at as dayDate,
          					er.real_money_amount as faileddeposit
          				from
          					entry_requests er
          				left join entries e on
          					er.id = e.entry_request_id
          				where
          					er.kind = 'deposit'
          					and er.status != 'succeeded') unsuccesfuldeposit on
          				ent.id = unsuccesfuldeposit.entry_request_id
          			left join (
          				select
          					case
          						when b.status = 'settled' then b.bet_settlement_status_achieved_at
          						else b.created_at
          					end as dayDate,
          					e.entry_request_id as entry_request_id,
          					b.id as betid,
          					e.kind,
          					b.customer_id,
          					b.status,
          					-e.base_currency_real_money_amount as real_money_bet,
          					-e.base_currency_bonus_amount as bonus_money_bet,
          					case
          						when b.created_at > ev.start_at then 'Live'
          						else 'Prematch'
          					end as bet_type
          				from
          					entries e
          				join bets b on
          					b.id = e.origin_id
          				join odds o on
          					b.odd_id = o.id
          				join markets m on
          					m.id = o.market_id
          				join events ev on
          					ev.id = m.event_id
          				where
          					e.kind = 'bet'
          					and b.status in ('manually_settled',
          					'settled')
          					and b.settlement_status != 'voided') bet on
          				bet.entry_request_id = ent.id
          				and bet.kind = ent.kind
          			left join (
          				select
          					e.created_at as dayDate,
          					e.entry_request_id as entry_request_id,
          					e.kind,
          					b.customer_id,
          					b.status,
          					e.base_currency_real_money_amount as real_money_win,
          					e.base_currency_bonus_amount as bonus_money_win,
          					case
          						when b.created_at > ev.start_at then 'Live'
          						else 'Prematch'
          					end as bet_type
          				from
          					entries e
          				join bets b on
          					b.id = e.origin_id
          				join odds o on
          					b.odd_id = o.id
          				join markets m on
          					m.id = o.market_id
          				join events ev on
          					ev.id = m.event_id
          				where
          					e.kind = 'win'
          					and b.status in ('manually_settled',
          					'settled')) win on
          				win.entry_request_id = ent.id
          				and win.kind = ent.kind
          			left join (
          				select
          					case
          						when e.created_at is not null then now()
          					end as dayDate,
          					e.entry_request_id as entry_request_id,
          					e.kind,
          					b.customer_id,
          					b.odd_value,
          					b.status,
          					-e.base_currency_real_money_amount as pending_real_money_bet,
          					-e.base_currency_bonus_amount as pending_bonus_money_bet
          				from
          					entries e
          				join bets b on
          					b.id = e.origin_id
          				where
          					e.kind = 'bet'
          					and b.status in ('accepted')) pending on
          				pending.entry_request_id = ent.id
          				and pending.kind = ent.kind
          			left join (
          				select
          					er.id as id,
          					-e.base_currency_bonus_amount as rolledback_bonus_win,
          					-e.base_currency_real_money_amount as rolledback_real_money_win,
          					case
          						when b.created_at > ev.start_at then 'Live'
          						else 'Prematch'
          					end as bet_type
          				from
          					entry_requests er
          				join entries e on
          					e.entry_request_id = er.id
          				join bets b on
          					b.id = e.origin_id
          				join odds o on
          					b.odd_id = o.id
          				join markets m on
          					m.id = o.market_id
          				join events ev on
          					ev.id = m.event_id
          				where
          					er.kind = 'rollback'
          					and b.settlement_status = 'won') as rolledbackwin on
          				rolledbackwin.id = ent.id
          			left join (
          				select
          					er.id as id,
          					-e.base_currency_bonus_amount as rolledback_bonus_bet,
          					-e.base_currency_real_money_amount as rolledback_real_money_bet,
          					case
          						when b.created_at > ev.start_at then 'Live'
          						else 'Prematch'
          					end as bet_type
          				from
          					entry_requests er
          				join entries e on
          					e.entry_request_id = er.id
          				join bets b on
          					b.id = e.origin_id
          				join odds o on
          					b.odd_id = o.id
          				join markets m on
          					m.id = o.market_id
          				join events ev on
          					ev.id = m.event_id
          				where
          					er.kind = 'rollback'
          					and b.settlement_status = 'lost') as rolledbackbet on
          				rolledbackbet.id = ent.id
          			left join (
          				select
          					e.entry_request_id,
          					e.balance_eur as balance_eur
          				from
          					(
          					select
          						e.id as entry_id,
          						er.id as entry_request_id,
          						e.balance_amount_after / c.exchange_rate as balance_eur
          					from
          						entries e
          					join wallets w on
          						w.id = e.wallet_id
          					join currencies c on
          						c.id = w.currency_id
          					join entry_requests er on
          						er.id = e.entry_request_id) e
          				join (
          					select
          						w.customer_id,
          						max(e.id) as maxid
          					from
          						entries e
          					join wallets w on
          						w.id = e.wallet_id
          					group by
          						1) b on
          					b.maxid = e.entry_id) balance on
          				balance.entry_request_id = ent.id
          			left join (
          				select
          					a.depositid as entry_request_id,
          					a.customer_id as customer_id,
          					b.deposit_time as ftd_dayDate,
          					a.real_money_ftd as real_money_ftd,
          					a.bonus_money_ftd as bonus_money_ftd
          				from
          					(
          					select
          						er.id as depositid,
          						er.created_at as deposit_time,
          						er.customer_id,
          						e.base_currency_real_money_amount as real_money_ftd,
          						e.base_currency_bonus_amount as bonus_money_ftd
          					from
          						entry_requests er
          					join entries e on
          						er.id = e.entry_request_id
          					where
          						er.kind = 'deposit'
          						and er.status = 'succeeded'
          						and er.mode != 'cashier') a
          				join (
          					select
          						er.customer_id,
          						min(er.created_at) as deposit_time
          					from
          						entry_requests er
          					join entries e on
          						er.id = e.entry_request_id
          					where
          						er.kind = 'deposit'
          						and er.status = 'succeeded'
          						and er.mode != 'cashier'
          					group by
          						1) b on
          					b.customer_id = a.customer_id
          					and b.deposit_time = a.deposit_time) as ftdtable on
          				ftdtable.entry_request_id = ent.id) a) b
          	group by
          		1) c
          where date(c.dayDate) = current_date-1
          order by
          	1 desc;
        SQL
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
