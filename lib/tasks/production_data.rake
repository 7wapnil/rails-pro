namespace :production_data do
  namespace :every_matrix do
    desc 'Set all every matrix entities as activated'
    task set_as_activated: :environment do
      %i[every_matrix_play_items
         every_matrix_vendors
         every_matrix_content_providers].each do |table|
        ActiveRecord::Base
          .connection
          .execute("UPDATE #{table} SET external_status = 'activated'")
      end
    end
  end

  desc 'Generate slugs'
  task generate_slugs: :environment do
    range = OddsFeed::Radar::ScheduledEvents::EventScheduleLoader::DEFAULT_RANGE

    Event.where("events.slug IS NULL OR events.slug = ''")
         .where('events.start_at > ?', range.ago.beginning_of_day)
         .find_each(&:save)
    Event.where("slug IS NULL OR slug = ''")
         .update_all("slug = CONCAT(id, '-', LOWER(REPLACE(name, ' ', '-')))")

    Title.where("slug IS NULL OR slug = ''").find_each(&:save)

    EventScope.joins(:events)
              .where("event_scopes.slug IS NULL OR event_scopes.slug = ''")
              .where('events.start_at > ?', range.ago.beginning_of_day)
              .distinct
              .find_each(&:save)
    EventScope
      .where("slug IS NULL OR slug = ''")
      .update_all("slug = CONCAT(id, '-', LOWER(REPLACE(name, ' ', '-')))")

    EveryMatrix::Category.where("context IS NULL OR context = ''")
                         .find_each(&:save)
    EveryMatrix::ContentProvider.where("slug IS NULL OR slug = ''")
                                .find_each(&:save)
    EveryMatrix::Vendor.where("slug IS NULL OR slug = ''").find_each(&:save)
    EveryMatrix::PlayItem.where("slug IS NULL OR slug = ''").find_each(&:save)
  end

  desc 'Reset event meta tag descriptions'
  task reset_event_meta_descriptions: :environment do
    Event.where('meta_description = name').update_all('meta_description = NULL')
  end

  desc 'Fill static meta data'
  task fill_static_meta_data: :environment do
    EveryMatrix::Category.find_by(context: 'favorites')&.update(
      meta_title: 'arcanebet - Public Favorites',
      meta_description: 'Curious what the majority of our Online Casino players hold most dear to their sessions? Behold a complete list of the most played Video Slots, that our public simply adores!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'golden-oldies')&.update(
      meta_title: 'arcanebet - Oldies but Goldies Section',
      meta_description: 'Feeling nostalgic about the good old days, with classic fruit games and unforgettable slots that have transcended time? You simply have to check our Oldies’Goldies section right away!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'jackpots')&.update(
      meta_title: 'arcanebet - Jackpot Games',
      meta_description: 'Whether it’s an exciting in-game Jackpot, or a huge Progressive one, you name it, we have it! Mega Moolah, Divine Fortune and several other giant Jackpots are one click away!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'new')&.update(
      meta_title: 'arcanebet - New Slot & Table Games',
      meta_description: 'One thing you can be sure of, is that we will always be up-to-date with the coolest new releases in matters of online video slots. Make sure to check out our latest additions every week!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'slots')&.update(
      meta_title: 'arcanebet - Video Slots Collection',
      meta_description: 'Who doesn’t love Casino video slots? We’ve rounded up a gigantic collection, of over 3000 popular titles, so you can virtually try out something new every day, and never get bored!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'table-games')&.update(
      meta_title: 'arcanebet - Table Games Collection',
      meta_description: 'Never been much of a pokies fan, and always inclined more towards serious adult games? Whether it’s Hold’em or Roulette, Blackjack or Baccarat, our Table Games section is the place for you!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'blackjack')&.update(
      meta_title: 'arcanebet - Live Blackjack Section',
      meta_description: 'If you’re looking for that hot 21, and the best tables to score it, we have what you need. Enjoy a wide selection of cool Blackjack versions from Evolution and NetEnt where card dreams come true!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'hot-tables')&.update(
      meta_title: 'arcanebet - Hottest Live Dealer Tables',
      meta_description: 'Wondering where the best Live action is? Check out our Hot Tables section, where you will only find the most populated and played Live Dealer Games of the moment! Only for straight-shooters!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'other-tables')&.update(
      meta_title: 'arcanebet - Other Live Dealer Tables',
      meta_description: 'Tired of the same all classic card and roulette games? No problem, just visit our Other Tables Section, and discover a whole new range of exciting and rewarding Live Dealer Games! ' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'poker')&.update(
      meta_title: 'arcanebet - Live Poker Lounge',
      meta_description: 'Whether you like playing Three Card or Omaha Poker, or you’re at the peak of your Texas Hold’em phase, the arcanebet Poker Lounge has just any variation you can possibly think of!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Category.find_by(context: 'roulette')&.update(
      meta_title: 'arcanebet - Live Roulette Lobby',
      meta_description: 'Wondering what’s the most played table game of chance in history? That’s right, you guessed it, and arcanebet has just about any possible Roulette version or variation a player can wish for!' # rubocop:disable Metrics/LineLength
    )

    EveryMatrix::Vendor.find_by(slug: 'gamevy')&.update(
      meta_title: 'Gamevy Video & Table Slots at arcanebet Casino',
      meta_description: 'Gamevy? Simply put, a perfect blend between innovation and creativity in high-end online slot machines. See it for yourself with popular titles like Snake, or European Roulette Dark Mode!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'gamevy')&.update(
      meta_title: 'Gamevy Video & Table Slots at arcanebet Casino',
      meta_description: 'Gamevy? Simply put, a perfect blend between innovation and creativity in high-end online slot machines. See it for yourself with popular titles like Snake, or European Roulette Dark Mode!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'playson')&.update(
      meta_title: 'Playson Casino Games at arcanebet',
      meta_description: 'The masters of fruit themed slot machines from Playson are available now at arcanebet Casino. Enjoy classic titles like Sevens&Fruits or Joker Expand, and some seriously high volatility!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'playson')&.update(
      meta_title: 'Playson Casino Games at arcanebet',
      meta_description: 'The masters of fruit themed slot machines from Playson are available now at arcanebet Casino. Enjoy classic titles like Sevens&Fruits or Joker Expand, and some seriously high volatility!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'net-ent')&.update(
      meta_title: 'NetEnt Slots Collection at arcanebet Casino',
      meta_description: 'Looking for the absolute best slots of all time? Some of the classic NetEnt titles such as Gonzo’s Quest or Starburst are right here, next to modern releases like the Mega Pyramid!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'net-ent')&.update(
      meta_title: 'NetEnt Slots Collection at arcanebet Casino',
      meta_description: 'Looking for the absolute best slots of all time? Some of the classic NetEnt titles such as Gonzo’s Quest or Starburst are right here, next to modern releases like the Mega Pyramid!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'bet-soft')&.update(
      meta_title: 'BetSoft meets arcanebet Casino',
      meta_description: 'Betsoft needs no introduction, being one of the oldest and most acclaimed providers in the industry. Enjoy classic titles like Birds! along to modern releases like Take the Bank right now!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'bet-soft')&.update(
      meta_title: 'BetSoft meets arcanebet Casino',
      meta_description: 'Betsoft needs no introduction, being one of the oldest and most acclaimed providers in the industry. Enjoy classic titles like Birds! along to modern releases like Take the Bank right now!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'oryx-gaming')&.update(
      meta_title: 'Oryx Gaming Center at arcanebet Casino',
      meta_description: 'Oryx Gaming is one of those over-achieving developers, mostly know for its delightful collaboration with Gammomat. Win big with the entire Books & Bulls series, at arcanebet Casino!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'pariplay')&.update(
      meta_title: 'Pariplay Ltd. slots at arcanebet Casino',
      meta_description: 'PariPlay is a leading provider mostly known for its ridiculously fun games, developed in-house. Renowned online video slots such as Lucky Vegas or Parrot’s Gold are now live at arcanebet!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'relax-gaming')&.update(
      meta_title: 'Relax Gaming slots at arcanebet Casino',
      meta_description: 'Zombie Queen, Tower Tumble, Joker Jackpot, and Snake Arena are now live at arcanebet Casino. Enjoy them along to the other great titles from innovative game developer Relax Gaming!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'relax-gaming')&.update(
      meta_title: 'Relax Gaming slots at arcanebet Casino',
      meta_description: 'Zombie Queen, Tower Tumble, Joker Jackpot, and Snake Arena are now live at arcanebet Casino. Enjoy them along to the other great titles from innovative game developer Relax Gaming!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'evolution-gaming')&.update(
      meta_title: 'Evolution Gaming - Live Dealer Excellency at arcanebet',
      meta_description: 'Evolution Gaming is the crown figure when it comes to Live Dealer games, in the iGaming industry. Play your favourite Blackjack, Roulette, Baccarat versions at the arcanebet Live Tables!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'evolution-gaming')&.update(
      meta_title: 'Evolution Gaming - Live Dealer Excellency at arcanebet',
      meta_description: 'Evolution Gaming is the crown figure when it comes to Live Dealer games, in the iGaming industry. Play your favourite Blackjack, Roulette, Baccarat versions at the arcanebet Live Tables!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'elk-gaming')&.update(
      meta_title: 'ELK Studios headquarters at arcanebet Casino',
      meta_description: 'Swedish developer ELK Studious is well-known for highly entertaining online video slots, and generous payouts. Enjoy the popular Gold series, along to El Toro and Hit It Big at arcanebet!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'spigo')&.update(
      meta_title: 'Enjoy Spigo Slots at arcanebet Casino',
      meta_description: 'Spigo is the master of casual online video slots, having redefined the notion of skill games with titles like Starlight, Tvoli, or Diamonds. Put your skills to test right now, at arcanebet!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'spigo')&.update(
      meta_title: 'Enjoy Spigo Slots at arcanebet Casino',
      meta_description: 'Spigo is the master of casual online video slots, having redefined the notion of skill games with titles like Starlight, Tvoli, or Diamonds. Put your skills to test right now, at arcanebet!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'quick-spin')&.update(
      meta_title: 'Quickspin Online Slots at arcanebet Casino',
      meta_description: 'Quickspin, one of the most innovative software developers in the industry, is responsible for some amazing video slots like Skullz Up!, or Tigers Glory. Give they a quick spin at arcanebet!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'blueprint')&.update(
      meta_title: 'Play Blueprint Slots at arcanebet Casino',
      meta_description: 'Meet Blueprint Gaming, a software provider with a keen eye for details, and a passion for high-quality entertainment, as seen in Diamond Mine Megaways™, or Gun Slinger: Fully Loaded!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'red-tiger-gaming')&.update(
      meta_title: 'Red Tiger Gaming Video Slots at arcanebet Casino',
      meta_description: 'Meet veteran online software provider Red Tiger Gaming, a force to be reckoned, responsible for dozens of awards-winning titles like Asian Fortune, Cinderella, or Gemtastic!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'red-tiger-gaming')&.update(
      meta_title: 'Red Tiger Gaming Video Slots at arcanebet Casino',
      meta_description: 'Meet veteran online software provider Red Tiger Gaming, a force to be reckoned, responsible for dozens of awards-winning titles like Asian Fortune, Cinderella, or Gemtastic!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'bee-fee')&.update(
      meta_title: 'Bee-Fee Limited games at arcanebet Casino',
      meta_description: 'Enjoy the top online video slots from from upcoming provider Bee-Fee in premiere! We’re talking popular names like Alice in Wonderland, Dark Carnivale, or Continent Africa right now!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'bee-fee')&.update(
      meta_title: 'Bee-Fee Limited games at arcanebet Casino',
      meta_description: 'Enjoy the top online video slots from from upcoming provider Bee-Fee in premiere! We’re talking popular names like Alice in Wonderland, Dark Carnivale, or Continent Africa right now!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'pragmatic-play')&.update(
      meta_title: 'Pragmatic Play meets arcanebet Casino',
      meta_description: 'Vegas is now at your fingertips, courtesy to Pragmatic Play, a revolutionary provider that brought us amazing titles such as Wolf Gold, Buffalo King, and Hot Chilli, and so many more!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'pragmatic-play')&.update(
      meta_title: 'Pragmatic Play meets arcanebet Casino',
      meta_description: 'Vegas is now at your fingertips, courtesy to Pragmatic Play, a revolutionary provider that brought us amazing titles such as Wolf Gold, Buffalo King, and Hot Chilli, and so many more!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'microgaming')&.update(
      meta_title: 'Microgaming Video, Table, and Live Casino Games',
      meta_description: 'Enjoy the complete portfolio of Microgaming Online Casino Slots, Table and Live Dealer Games at arcanebet Casino. Popular titles like Mega Moolah or Break da Bank Again are waiting for you!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'microgaming')&.update(
      meta_title: 'Microgaming Video, Table, and Live Casino Games',
      meta_description: 'Enjoy the complete portfolio of Microgaming Online Casino Slots, Table and Live Dealer Games at arcanebet Casino. Popular titles like Mega Moolah or Break da Bank Again are waiting for you!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::Vendor.find_by(slug: 'egt')&.update(
      meta_title: 'EGT Interactive at arcanebet Casino',
      meta_description: 'Prepare to discover the revolutionary gaming experience brought in by EGT Interactive! Consecrated titles like Burning Hot, Halloween, or Egypt Sky are waiting for you to hit a lucky spin!' # rubocop:disable Metrics/LineLength
    )
    EveryMatrix::ContentProvider.find_by(slug: 'egt')&.update(
      meta_title: 'EGT Interactive at arcanebet Casino',
      meta_description: 'Prepare to discover the revolutionary gaming experience brought in by EGT Interactive! Consecrated titles like Burning Hot, Halloween, or Egypt Sky are waiting for you to hit a lucky spin!' # rubocop:disable Metrics/LineLength
    )
  end

  desc 'Change esports title slugs'
  task change_esports_title_slugs: :environment do
    Title
      .esports
      .where("slug ILIKE 'e-sport%'")
      .update_all("slug = REPLACE(slug, 'e-sport', 'esport')")
  end

  desc 'Run all task regarding SEO improvement'
  task prepare_seo_improvement: :environment do
    Rake::Task['production_data:reset_event_meta_descriptions'].invoke
    Rake::Task['production_data:generate_slugs'].invoke
    Rake::Task['production_data:fill_static_meta_data'].invoke
    Rake::Task['production_data:change_esports_title_slugs'].invoke
  end
end
